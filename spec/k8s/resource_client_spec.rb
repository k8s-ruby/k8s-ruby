# frozen_string_literal: true

RSpec.describe K8s::ResourceClient do
  include FixtureHelpers

  let(:transport_options) { {} }
  let(:transport) { K8s::Transport.new('http://localhost:8080', **transport_options) }

  context "for the nodes API" do
    let(:api_client) { K8s::APIClient.new(transport, 'v1') }
    let(:api_resource) do
      K8s::API::MetaV1::APIResource.new(
        name: "nodes",
        singularName: "",
        namespaced: false,
        kind: "Node",
        verbs: %w[create delete deletecollection get list patch update watch],
        shortNames: %w[no]
      )
    end

    subject { described_class.new(transport, api_client, api_resource) }

    describe '#path' do
      it 'returns root path' do
        expect(subject.path(namespace: nil)).to eq '/api/v1/nodes'
      end

      it 'returns a path to node' do
        expect(subject.path('testNode')).to eq '/api/v1/nodes/testNode'
      end

      it 'returns a path to node subresource' do
        expect(subject.path('testNode', subresource: 'proxy')).to eq '/api/v1/nodes/testNode/proxy'
      end
    end

    context "GET /api/v1/nodes" do
      before do
        stub_request(:get, 'localhost:8080/api/v1/nodes')
          .to_return(
            status: 200,
            body: fixture('api/nodes-list.json'),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      describe '#list' do
        it "returns an array of resources" do
          list = subject.list

          expect(list).to match [K8s::Resource]
          expect(list.map do |item|
            {
              kind: item.kind,
              namespace: item.metadata.namespace,
              name: item.metadata.name
            }
          end).to match [
            { kind: "Node", namespace: nil, name: "ubuntu-xenial" }
          ]
        end
      end
    end

    context "GET /api/v1/nodes/*" do
      before do
        stub_request(:get, 'localhost:8080/api/v1/nodes/ubuntu-xenial')
          .to_return(
            status: 200,
            body: fixture('api/nodes-get.json'),
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      describe '#get' do
        it "returns a resource" do
          obj = subject.get('ubuntu-xenial')

          expect(obj).to match K8s::Resource
          expect(obj.kind).to eq "Node"
          expect(obj.metadata.namespace).to be nil
          expect(obj.metadata.name).to eq "ubuntu-xenial"
        end
      end
    end

    context "PUT /api/v1/nodes/*" do
      let(:resource) do
        K8s::Resource.new(
          kind: 'Node',
          metadata: { name: 'test', resourceVersion: "1" },
          spec: { unschedulable: true }
        )
      end

      before do
        stub_request(:put, 'localhost:8080/api/v1/nodes/test')
          .with(
            headers: { 'Content-Type' => 'application/json' },
            body: {
              'kind' => 'Node',
              'metadata' => { 'name' => 'test', 'resourceVersion' => "1" },
              'spec' => { 'unschedulable' => true }
            }
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: JSON.generate(resource.to_hash)
          )
      end

      describe '#update_resource' do
        it "returns a resource" do
          obj = subject.update_resource(resource)

          expect(obj).to match K8s::Resource
          expect(obj.kind).to eq "Node"
          expect(obj.metadata.name).to eq "test"
        end
      end
    end

    context "POST /api/v1/nodes/" do
      let(:resource) do
        K8s::Resource.new(
          kind: 'Node',
          metadata: { name: 'test' },
          spec: { unschedulable: true }
        )
      end

      before do
        stub_request(:post, 'localhost:8080/api/v1/nodes')
          .with(
            headers: { 'Content-Type' => 'application/json' },
            body: {
              'kind' => 'Node',
              'metadata' => { 'name' => 'test' },
              'spec' => { 'unschedulable' => true }
            }
          )
          .to_return(
            status: 201,
            headers: { 'Content-Type' => 'application/json' },
            body: JSON.generate(resource.to_hash)
          )
      end

      describe '#create_resource' do
        it "returns a resource" do
          obj = subject.create_resource(resource)

          expect(obj).to match K8s::Resource
          expect(obj.kind).to eq "Node"
          expect(obj.metadata.name).to eq "test"
        end
      end
    end
  end

  context "for the nodes status API" do
    let(:api_client) { K8s::APIClient.new(transport, 'v1') }
    let(:api_resource) do
      K8s::API::MetaV1::APIResource.new(
        name: "nodes/status",
        singularName: "",
        namespaced: false,
        kind: "Node",
        verbs: %w[get patch update]
      )
    end

    subject { described_class.new(transport, api_client, api_resource) }

    describe '#path' do
      it 'returns a path to node subresource' do
        expect(subject.path('test')).to eq '/api/v1/nodes/test/status'
      end
    end

    context "PUT /api/v1/nodes/*/status" do
      let(:resource) do
        K8s::Resource.new(
          kind: 'Node',
          metadata: { name: 'test', resourceVersion: "1" },
          status: { foo: 'bar' }
        )
      end

      before do
        stub_request(:put, 'localhost:8080/api/v1/nodes/test/status')
          .with(
            headers: { 'Content-Type' => 'application/json' },
            body: {
              'kind' => 'Node',
              'metadata' => { 'name' => 'test', 'resourceVersion' => "1" },
              'status' => { 'foo' => 'bar' }
            }
          )
          .to_return(
            status: 200,
            headers: { 'Content-Type' => 'application/json' },
            body: JSON.generate(resource.to_hash)
          )
      end

      describe '#update_resource' do
        it "returns a resource" do
          obj = subject.update_resource(resource)

          expect(obj).to match K8s::Resource
          expect(obj.kind).to eq "Node"
          expect(obj.metadata.name).to eq "test"
        end
      end
    end
  end

  context "for the pods API" do
    let(:api_client) { K8s::APIClient.new(transport, 'v1') }
    let(:api_resource) do
      K8s::API::MetaV1::APIResource.new(
        name: "pods",
        singularName: "",
        namespaced: true,
        kind: "Pod",
        verbs: %w[create delete deletecollection get list patch update watch exec log],
        shortNames: %w[po],
        categories: %w[all]
      )
    end

    subject { described_class.new(transport, api_client, api_resource) }

    let(:resource) do
      K8s::Resource.new(
        kind: 'Pod',
        metadata: { name: 'test', namespace: 'default' }
      )
    end
    let(:resource_list) { K8s::API::MetaV1::List.new(metadata: {}, items: [resource]) }

    context "POST /api/v1/pods/namespaces/default/pods" do
      before do
        stub_request(:post, 'localhost:8080/api/v1/namespaces/default/pods')
          .with(
            headers: { 'Content-Type' => 'application/json' },
            body: {
              'kind' => 'Pod',
              'metadata' => { 'name' => 'test', 'namespace' => 'default' }
            }
          )
          .to_return(
            status: 201,
            headers: { 'Content-Type' => 'application/json' },
            body: JSON.generate(resource.to_hash)
          )
      end

      describe '#create_resource' do
        it "returns a resource" do
          obj = subject.create_resource(resource)

          expect(obj).to match K8s::Resource
          expect(obj.kind).to eq "Pod"
          expect(obj.metadata.namespace).to eq "default"
          expect(obj.metadata.name).to eq "test"
        end
      end
    end

    context "PATCH /api/v1/pods/namespaces/default/pods/test" do
      before do
        stub_request(:patch, 'localhost:8080/api/v1/namespaces/default/pods/test')
          .with(
            headers: { 'Content-Type' => 'application/strategic-merge-patch+json' },
            body: {
              'spec' => { 'nodeName': 'foo' }
            }.to_json # XXX: webmock doesn't understand +json
          )
          .to_return(
            status: 201,
            headers: { 'Content-Type' => 'application/json' },
            body: JSON.generate(resource.to_hash)
          )
      end

      describe '#merge_patch' do
        it "returns a resource" do
          obj = subject.merge_patch('test', { 'spec' => { 'nodeName' => 'foo' } }, namespace: 'default')

          expect(obj).to match K8s::Resource
          expect(obj.kind).to eq "Pod"
          expect(obj.metadata.namespace).to eq "default"
          expect(obj.metadata.name).to eq "test"
        end
      end
    end

    context "DELETE /api/v1/pods/*" do
      before do
        allow(transport).to receive(:need_delete_body?).and_return(false)
        stub_request(:delete, 'localhost:8080/api/v1/namespaces/default/pods/test')
          .to_return(
            status: 200,
            body: JSON.generate(resource.to_hash),
            headers: { 'Content-Type' => 'application/json' }
          )
        stub_request(:delete, 'localhost:8080/api/v1/namespaces/default/pods?labelSelector=app=test')
          .to_return(
            status: 200,
            body: JSON.generate(resource_list.to_hash), # XXX: to_json?
            headers: { 'Content-Type' => 'application/json' }
          )
      end

      describe '#delete' do
        it "deletes a resource and returns it" do
          obj = subject.delete('test', namespace: 'default')

          expect(obj).to match K8s::Resource
          expect(obj.kind).to eq "Pod"
          expect(obj.metadata.name).to eq "test"
        end
      end

      describe '#delete_collection' do
        it "deletes resources and returns them" do
          items = subject.delete_collection(namespace: 'default', labelSelector: 'app=test')

          expect(items).to match [K8s::Resource]
          expect(items[0].kind).to eq "Pod"
          expect(items[0].metadata.name).to eq "test"
        end
      end

      describe '#delete_resource' do
        it "deletes a resource and returns it" do
          obj = subject.delete_resource(resource)

          expect(obj).to match K8s::Resource
          expect(obj.kind).to eq "Pod"
          expect(obj.metadata.name).to eq "test"
        end
      end
    end

    context 'GET /api/v1/pods/*' do
      describe '#watch' do
        it 'configures transport for streaming request' do
          expect(transport).to receive(:request).with(
            hash_including(
              method: 'GET',
              read_timeout: nil,
              query: hash_including(
                'watch' => '1'
              ),
              response_block: kind_of(Proc)
            )
          )
          subject.watch
        end

        it 'sets timeout if given' do
          expect(transport).to receive(:request).with(
            hash_including(
              query: hash_including(
                'watch' => '1',
                'timeoutSeconds' => 60
              )
            )
          )
          subject.watch(timeout: 60)
        end
      end

      describe '#exec' do
        let(:ws) { double(Faye::WebSocket::Client, send: nil) }

        before do
          allow(Faye::WebSocket::Client).to receive(:new).and_return(ws)
          allow(Termios).to receive(:tcgetattr).and_return(double(dup: double(lflag: 0, :'lflag=' => 0)))
          allow(Termios).to receive(:tcsetattr).and_return(nil)
          allow(ws).to receive(:on)
        end

        describe "authorization" do
          before { exec }

          context "when client cert and key data are provided" do
            let(:transport_options) {
              { client_cert_data: 'dummy-client-cert-data', client_key_data: 'dummy-client-key-data' }
            }

            it 'creates a websocket connection using the client cert and key data' do
              expect(Faye::WebSocket::Client).to have_received(:new).with(
                'ws://localhost:8080/api/v1/namespaces/test-namespace/pods/test-pod/exec?command=%2Fbin%2Fbash&container=test-container&stdin=true&stdout=true&tty=true',
                [],
                headers: {},
                tls: hash_including(
                  cert_chain_file: have_file_content('dummy-client-cert-data'),
                  private_key_file: have_file_content('dummy-client-key-data'),
                )
              )
            end
          end

          context "when client cert and key files are provided" do
            let(:transport_options) {
              { client_cert: '/var/run/dummy-client-cert-file.crt', client_key: '/var/run/dummy-client-key-file.key' }
            }

            it 'creates a websocket connection using the client cert and key files' do
              expect(Faye::WebSocket::Client).to have_received(:new).with(
                'ws://localhost:8080/api/v1/namespaces/test-namespace/pods/test-pod/exec?command=%2Fbin%2Fbash&container=test-container&stdin=true&stdout=true&tty=true',
                [],
                headers: {},
                tls: hash_including(
                  cert_chain_file: transport_options[:client_cert],
                  private_key_file: transport_options[:client_key],
                )
              )
            end
          end

          context "when authorization token is provided" do
            let(:transport_options) {
              { auth_token: 'dummy-auth-token' }
            }

            it 'creates a websocket connection using the authorization token' do
              expect(Faye::WebSocket::Client).to have_received(:new).with(
                'ws://localhost:8080/api/v1/namespaces/test-namespace/pods/test-pod/exec?command=%2Fbin%2Fbash&container=test-container&stdin=true&stdout=true&tty=true',
                [],
                headers: hash_including(
                  'Authorization' => 'Bearer dummy-auth-token'
                ),
                tls: hash_including(
                  cert_chain_file: nil,
                  private_key_file: nil,
                )
              )
            end
          end
        end

        describe "command arguments" do
          it "passes the command arguments to the websocket connection" do
            exec(command: ['ls', '-la'])
            expect(Faye::WebSocket::Client).to have_received(:new).with(
              'ws://localhost:8080/api/v1/namespaces/test-namespace/pods/test-pod/exec?command=ls&command=-la&container=test-container&stdin=true&stdout=true&tty=true',
              [],
              anything
            )
          end
        end

        describe "stdin" do
          before do
            allow(EM).to receive(:open_keyboard).and_invoke( -> (handler) { EM.attach($stdin, handler) })
          end

          after do
            $stdin = STDIN
          end

          it "passes the stdin input to the websocket connection with the stdin channel 0" do
            rd, wd = IO.pipe
            $stdin = rd

            exec do
              wd.write("ls\n")
            end

            expect(ws).to have_received(:send).with([0, 108, 115, 10])
          end
        end

        private
        def em
          EM.run do
            yield
            EM.stop
          end
        end

        def exec(name: 'test-pod', namespace: 'test-namespace', command: '/bin/bash', container: 'test-container')
          em do
            subject.exec(
              name: name,
              namespace: namespace,
              command: command,
              container: container
            )
            yield if block_given?
            EM.stop
          end
        end
      end
    end

    describe '#logs' do
      let(:pod_name) { 'test-pod' }
      let(:namespace) { 'test-namespace' }
      let(:container) { 'test-container' }

      context "when getting logs without following" do
        before do
          stub_request(:get, "localhost:8080/api/v1/namespaces/#{namespace}/pods/#{pod_name}/log?container=#{container}&follow=false&timestamps=false")
            .to_return(
              status: 200,
              body: "log line 1\nlog line 2\n",
              headers: { 'Content-Type' => 'text/plain' }
            )
        end

        it "returns the logs as a string" do
          logs = subject.logs(name: pod_name, namespace: namespace, container: container)
          expect(logs).to eq "log line 1\nlog line 2\n"
        end
      end

      context "when following logs" do
        let(:chunks) { ["log line 1\n", "log line 2\n"] }
        let(:log_chunks) { [] }

        before do
          expect(transport).to receive(:request).with(
            hash_including(
              method: 'GET',
              path: "/api/v1/namespaces/#{namespace}/pods/#{pod_name}/log",
              query: hash_including(
                container: container,
                follow: true
              ),
              read_timeout: 3600,
              response_block: instance_of(Proc)
            )
          ) do |args|
            # Extract the response_block from the args
            response_block = args[:response_block]
            
            # Simulate streaming response by calling the provided block with chunks
            chunks.each do |chunk|
              response_block.call(chunk)
            end
            {}
          end
        end

        it "yields each chunk of logs to the block" do
          subject.logs(name: pod_name, namespace: namespace, container: container, follow: true) do |chunk|
            log_chunks << chunk
          end
          expect(log_chunks).to eq chunks
        end
      end

      context "with additional parameters" do
        before do
          stub_request(:get, "localhost:8080/api/v1/namespaces/#{namespace}/pods/#{pod_name}/log?container=#{container}&follow=false&timestamps=true&tailLines=10&sinceTime=2023-01-01T00:00:00Z")
            .to_return(
              status: 200,
              body: "2023-01-01T00:00:01Z log line 1\n2023-01-01T00:00:02Z log line 2\n",
              headers: { 'Content-Type' => 'text/plain' }
            )
        end

        it "includes all parameters in the request" do
          logs = subject.logs(
            name: pod_name,
            namespace: namespace,
            container: container,
            timestamps: true,
            tail_lines: 10,
            since_time: '2023-01-01T00:00:00Z'
          )
          expect(logs).to eq "2023-01-01T00:00:01Z log line 1\n2023-01-01T00:00:02Z log line 2\n"
        end
      end
    end
  end
end
