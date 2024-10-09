RSpec.describe Anthropic::Client do
  describe "#messages with tool use" do
    let(:model) { "claude-3-haiku-20240307" }
    let(:max_tokens) { 1024 }
    let(:tools) do
      [
        {
          name: "get_weather",
          description: "Get the current weather in a given location",
          input_schema: {
            type: "object",
            properties: {
              location: {
                type: "string",
                description: "The city and state, e.g. San Francisco, CA"
              }
            },
            required: ["location"]
          }
        }
      ]
    end
    let(:messages) { [{ role: "user", content: "What is the weather like in San Francisco?" }] }

    let(:response) do
      Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)).messages(
        parameters: {
          model: model,
          messages: messages,
          max_tokens: max_tokens,
          tools: tools
        }
      )
    end

    let(:cassette) { "#{model} tool use weather".downcase }

    it "succeeds and includes tool use" do
      VCR.use_cassette(cassette) do
        expect(response["content"]).to be_an(Array)
        expect(response["stop_reason"]).to eq("tool_use")

        tool_use = response["content"].find { |item| item["type"] == "tool_use" }
        expect(tool_use).not_to be_nil
        expect(tool_use["name"]).to eq("get_weather")
        expect(tool_use["input"]).to include("location" => "San Francisco, CA")
      end
    end
  end
end
