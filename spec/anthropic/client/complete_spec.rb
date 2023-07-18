RSpec.describe Anthropic::Client do
  describe "#completions" do
    context "with a prompt and max_tokens", :vcr do
      let(:prompt) { "Once upon a time" }
      let(:max_tokens) { 5 }

      let(:response) do
        Anthropic::Client.new.completions(
          parameters: {
            model: model,
            max_tokens_to_sample: max_tokens,
            prompt: prompt
          }
        )
      end
      let(:text) { response.dig("choices", 0, "text") }
      let(:cassette) { "#{model} completions #{prompt}".downcase }

      context "with model: claude-2" do
        let(:model) { "claude-2" }

        it "succeeds" do
          VCR.use_cassette(cassette) do
            expect(response["completion"].empty?).to eq(false)
          end
        end
      end
    end
  end
end
