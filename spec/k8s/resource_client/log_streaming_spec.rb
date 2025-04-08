# frozen_string_literal: true

RSpec.describe K8s::ResourceClient::Log do
  include FixtureHelpers

  let(:transport) { K8s::Transport.new('http://localhost:8080') }
  let(:api_client) { K8s::APIClient.new(transport, 'v1') }
  let(:api_resource) do
    K8s::API::MetaV1::APIResource.new(
      name: "pods",
      singularName: "",
      namespaced: true,
      kind: "Pod",
      verbs: %w[log],
      shortNames: ["po"],
      categories: ["all"]
    )
  end

  subject { K8s::ResourceClient.new(transport, api_client, api_resource) }

  describe '#logs' do
    let(:pod_name) { 'test-pod' }
    let(:namespace) { 'test-namespace' }
    let(:log_chunks) { ["line 1\n", "line 2\n", "line 3\n"] }

    context "with follow: true" do
      before do
        expect(transport).to receive(:request).with(
          hash_including(
            method: 'GET',
            path: "/api/v1/namespaces/#{namespace}/pods/#{pod_name}/log",
            query: hash_including(follow: true),
            response_block: instance_of(Proc)
          )
        ) do |args|
          log_chunks.each { |chunk| args[:response_block].call(chunk) }
          {}
        end
      end

      it "yields each chunk of logs to the block" do
        received_chunks = []
        subject.logs(name: pod_name, namespace: namespace, follow: true) do |chunk|
          received_chunks << chunk
        end
        expect(received_chunks).to eq log_chunks
      end
    end

    context "without follow" do
      before do
        expect(transport).to receive(:request).with(
          hash_including(
            method: 'GET',
            path: "/api/v1/namespaces/#{namespace}/pods/#{pod_name}/log",
            query: hash_including(follow: false)
          )
        ).and_return("line 1\nline 2\nline 3\n")
      end

      it "returns the logs as a string" do
        logs = subject.logs(name: pod_name, namespace: namespace, follow: false)
        expect(logs).to eq "line 1\nline 2\nline 3\n"
      end
    end
  end
end
