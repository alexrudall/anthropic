RSpec.describe Anthropic::Client do
  let(:client) { Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)) }

  describe "#messages.batches" do
    let(:batch_requests) do
      [
        {
          custom_id: "test-prompt-1",
          params: {
            model: "claude-3-haiku-20240307",
            max_tokens: 100,
            messages: [{ role: "user", content: "Tell me a fact about testing" }]
          }
        },
        {
          custom_id: "test-prompt-2",
          params: {
            model: "claude-3-haiku-20240307",
            max_tokens: 100,
            messages: [{ role: "user", content: "Tell me a fact about specs" }]
          }
        }
      ]
    end

    shared_context "batch setup" do
      let(:setup_cassette_name) { raise "Must define setup_cassette_name" }
      let(:batch_id) do
        VCR.use_cassette("batch_#{setup_cassette_name}_setup") do
          client.messages.batches.create(parameters: { requests: batch_requests })["id"]
        end
      end
    end

    describe "#create" do
      let(:response) { client.messages.batches.create(parameters: { requests: batch_requests }) }

      it "succeeds" do
        VCR.use_cassette("batch_create") do
          expect(response["id"]).to be_a(String)
          expect(response["type"]).to eq("message_batch")
        end
      end
    end

    describe "#get" do
      include_context "batch setup"
      let(:setup_cassette_name) { "get" }

      it "succeeds" do
        VCR.use_cassette("batch_get") do
          response = client.messages.batches.get(id: batch_id)
          expect(response["id"]).to eq(batch_id)
          expect(response["type"]).to eq("message_batch")
        end
      end
    end

    describe "#results" do
      include_context "batch setup"
      let(:setup_cassette_name) { "results" }

      it "makes the correct API request" do
        VCR.use_cassette("batch_results") do
          response = client.messages.batches.results(id: batch_id)
          # If we get here, batch completed successfully
          expect(response).to be_an(Array)
          expect(response.first).to have_key("custom_id")
          expect(response.first).to have_key("result")
        rescue Faraday::ResourceNotFound => e
          # If we get here, batch is still processing
          error_body = e.response[:body]
          expect(error_body["type"]).to eq("error")
          expect(error_body["error"]["type"]).to eq("not_found_error")
          expect(error_body["error"]["message"]).to include("has no available results")
        end
      end
    end

    describe "#list" do
      include_context "batch setup"
      let(:setup_cassette_name) { "list" }

      it "succeeds" do
        VCR.use_cassette("batch_list") do
          response = client.messages.batches.list
          expect(response).to have_key("data")
          expect(response["data"]).to be_an(Array)
          expect(response["data"].first["type"]).to eq("message_batch")
        end
      end

      it "supports pagination parameters" do
        VCR.use_cassette("batch_list_with_params") do
          response = client.messages.batches.list(parameters: { limit: 1 })
          expect(response["data"].length).to be <= 1
        end
      end
    end

    describe "#cancel" do
      include_context "batch setup"
      let(:setup_cassette_name) { "cancel" }

      it "succeeds" do
        VCR.use_cassette("batch_cancel") do
          response = client.messages.batches.cancel(id: batch_id)
          expect(response["id"]).to eq(batch_id)
          expect(%w[canceling ended]).to include(response["processing_status"])
        end
      end
    end
  end
end
