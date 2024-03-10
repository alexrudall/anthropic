RSpec.describe Anthropic::Client do
  describe "#complete" do
    context "with a prompt and max_tokens", :vcr do
      let(:prompt) { "How high is the sky?" }
      let(:max_tokens) { 5 }

      let(:response) do
        Anthropic::Client.new(access_token: ENV['ANTHROPIC_API_KEY']).messages(
          parameters: {
            model: model,
            messages: [
              {
                role: "user",
                content: "How High is the Sky?"
              }
            ],
            max_tokens: max_tokens,
          }
        )
      end
      let(:text) { response.dig("choices", 0, "text") }
      let(:cassette) { "#{model} complete #{prompt}".downcase }

      context "with model: claude-2.1" do
        let(:model) { "claude-2.1" }

        it "succeeds" do
          VCR.use_cassette(cassette) do
            expect(response["content"].empty?).to eq(false)
          end
        end
      end
    end
  end
end
