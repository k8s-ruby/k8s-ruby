# frozen_string_literal: true

module K8s
  class ResourceClient
    module Exec
      def self.included(base)
        base.include(InstanceMethods)
        base.include(Logging)
      end

      module InstanceMethods
        require "eventmachine"
        require "faye/websocket"
        require "termios"
        require "tempfile"

        # Executes arbitrary commands in a container.
        #
        # @param name [String] name of the pod
        # @param namespace [String]
        # @param container [String] name of the container to execute the command in
        # @param command [Array<String>|String] command to execute. It accepts a single string or an array of strings if multiple arguments are needed.
        # @param stdin [Boolean] whether to stream stdin to the container
        # @param stdout [Boolean] whether to stream stdout from the container
        # @param tty [Boolean] whether to allocate a tty for the container
        # @yield [String] Optional block to yield the output of the command
        # @return [String, nil] output of the command. It returns nil if a block is given or tty is true.
        #
        # @example
        #   client.api('v1').resource('pods', namespace: 'default').exec(
        #     name: 'test-pod',
        #     container: 'shell',
        #     command: '/bin/sh'
        #   )
        # @example Open a shell:
        #   exec(name: 'my-pod', container: 'my-container', command: '/bin/sh')
        # @example Execute single command:
        #   exec(name: 'my-pod', container: 'my-container', command: 'date')
        # @example Pass multiple arguments:
        #   exec(name: 'my-pod', container: 'my-container', command: ['ls', '-la'])
        # @example Yield the output of the command:
        #  exec(
        #    name: "test-pod",
        #    container: "shell",
        #    command: [ "watch", "date" ],
        #  ) do |out|
        #    puts "local time #{Time.now}"
        #    puts "server time #{out}"
        #  end
        def exec(name:, namespace: @namespace, command:, container:, stdin: true, stdout: true, tty: true)
          query = {
            command: [command].flatten,
            container: container,
            stdin: !!stdin,
            stdout: !!stdout,
            tty: !!tty
          }

          exec_path = path(name, namespace: namespace, subresource: "exec")
          output = StringIO.new

          EM.run do
            ws = @transport.build_ws_conn(exec_path, query)

            ws.on :message do |event|
              out = event.data.pack("C*")

              if block_given?
                yield(out)
              elsif tty
                print out
              else
                output.write(out)
              end
            end

            ws.on :error do |event|
              logger.error(event.message)
            end

            term_attributes_original = Termios.tcgetattr($stdin)
            if tty
              term_attributes = term_attributes_original.dup
              term_attributes.lflag &= ~Termios::ECHO
              term_attributes.lflag &= ~Termios::ICANON
              Termios.tcsetattr($stdin, Termios::TCSANOW, term_attributes)

              EM.open_keyboard(Module.new do
                define_method(:receive_data) do |input|
                  input = [0] + input.unpack("C*")
                  ws.send(input)
                end
              end)
            end

            ws.on :close do
              Termios.tcsetattr($stdin, Termios::TCSANOW, term_attributes_original)
              EM.stop
            end
          end

          return if tty

          output.rewind
          output.read
        end
      end
    end
  end
end
