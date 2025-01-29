RSpec.describe Anthropic::HTTP do
  describe "logging errors" do
    let(:cassette) { "http post with error response".downcase }

    before do
      @original_stdout = $stdout
      $stdout = StringIO.new
    end

    after do
      $stdout = @original_stdout
    end

    context "when log_errors is not set" do
      let(:client) { Anthropic::Client.new(access_token: "invalid_token") }

      it "is disabled by default" do
        VCR.use_cassette(cassette, record: :none) do
          expect do
            client.messages.batches.create(
              parameters: {
                requests: [{
                  custom_id: "test-request",
                  params: {
                    model: "claude-3-haiku-20240307",
                    max_tokens: 124,
                    messages: [{ role: "user", content: "Hello, world" }]
                  }
                }]
              }
            )
          end.to raise_error Faraday::Error

          $stdout.rewind
          captured_stdout = $stdout.string
          expect(captured_stdout).not_to include("Anthropic HTTP Error")
        end
      end
    end

    describe "when log_errors is set to true" do
      let(:log_errors) { true }
      let(:client) { Anthropic::Client.new(access_token: "invalid_token", log_errors: log_errors) }

      it "logs errors" do
        VCR.use_cassette(cassette, record: :none) do
          expect do
            client.messages.batches.create(
              parameters: {
                requests: [{
                  custom_id: "test-request",
                  params: {
                    model: "claude-3-haiku-20240307",
                    max_tokens: 124,
                    messages: [{ role: "user", content: "Hello, world" }]
                  }
                }]
              }
            )
          end.to raise_error Faraday::Error

          $stdout.rewind
          captured_stdout = $stdout.string
          expect(captured_stdout).to include("Anthropic HTTP Error")
        end
      end
    end

    describe "when log_errors is set to false" do
      let(:log_errors) { false }
      let(:client) { Anthropic::Client.new(access_token: "invalid_token", log_errors: log_errors) }

      it "does not log errors" do
        VCR.use_cassette(cassette, record: :none) do
          expect do
            client.messages.batches.create(
              parameters: {
                requests: [{
                  custom_id: "test-request",
                  params: {
                    model: "claude-3-haiku-20240307",
                    max_tokens: 124,
                    messages: [{ role: "user", content: "Hello, world" }]
                  }
                }]
              }
            )
          end.to raise_error Faraday::Error

          $stdout.rewind
          captured_stdout = $stdout.string
          expect(captured_stdout).not_to include("Anthropic HTTP Error")
        end
      end
    end
  end
end
