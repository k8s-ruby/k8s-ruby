# frozen_string_literal: true

require 'logger'

module K8s
  class ResourceClient
    module Log
      def self.included(base)
        base.include(InstanceMethods)
        base.include(Logging)
      end

      module InstanceMethods
        # Get logs from a pod
        #
        # @param name [String] name of the pod
        # @param namespace [String]
        # @param container [String] name of the container to get logs from
        # @param timestamps [Boolean] include timestamps in the output
        # @param tail_lines [Integer] number of lines to show from the end of the logs
        # @param since_time [String] show logs since this time (RFC3339 format)
        # @param follow [Boolean] whether to follow the logs
        # @yield [String] Optional block to yield each chunk of logs
        # @return [String, nil] logs as a string. Returns nil if a block is given or follow is true.
        #
        # @example
        #   client.api('v1').resource('pods', namespace: 'default').logs(
        #     name: 'test-pod',
        #     container: 'app',
        #     follow: true
        #   ) do |chunk|
        #     puts chunk
        #   end
        def logs(name:, namespace: @namespace, container: nil, timestamps: false, tail_lines: nil, since_time: nil, follow: false)
          query = {
            container: container,
            timestamps: timestamps,
            tailLines: tail_lines,
            sinceTime: since_time,
            follow: follow
          }.compact

          log_path = path(name, namespace: namespace, subresource: "log")

          if block_given?
            # Use regular request with response_block for streaming
            @transport.request(
              method: 'GET',
              path: log_path,
              query: query,
              read_timeout: follow ? 3600 : 60, # Longer timeout for follow mode
              response_block: proc do |chunk|
                # Pass the chunk directly to the yield block
                yield chunk if chunk && !chunk.empty?
              end
            )

            return nil
          end

          # For follow without a block, warn as this isn't a recommended pattern
          if follow && !block_given?
            logger.warn "Following logs without a block won't stream properly"
          end

          # Regular synchronous request
          @transport.request(method: 'GET', path: log_path, query: query)
        end
      end
    end
  end
end
