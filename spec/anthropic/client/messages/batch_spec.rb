RSpec.describe Anthropic::Client do
  let(:client) { Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)) }
  let(:json_prompt) { "Answer in the provided JSON format. Only include JSON." }

  describe "#messages.batch" do
    context "batch messages" do
      let(:request_1) do
        {
          custom_id: "first-prompt-in-my-batch",
          params: {
              model: "claude-3-haiku-20240307",
              max_tokens: 100,
              messages: [
                  {
                      "role": "user",
                      "content": "Hey Claude, tell me a short fun fact about video games!",
                  }
              ],
          },
        }
      end

      let(:request_2) do
        {
          custom_id: "second-prompt-in-my-batch",
          params: {
              model: "claude-3-5-sonnet-20240620",
              max_tokens: 100,
              "messages": [
                  {
                      "role": "user",
                      "content": "Hey Claude, tell me a short fun fact about bees!",
                  }
              ],
          },
        }
      end

      let(:response) do
        Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)).batch_messages(
          [request_1, request_2]
        )
      end

      it "succeeds" do
        cassette = "batch_messages"
        VCR.use_cassette(cassette) do
          expect(response["id"].empty?).to eq(false)
        end
      end
    end
  end
end
