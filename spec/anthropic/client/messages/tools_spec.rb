RSpec.describe Anthropic::Client do
  describe "#messages with streaming tool use" do
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
    let(:chunks) { [] }
    let(:stream_results) { [] }

    let(:stream) do
      proc do |chunk|
        chunks << chunk
      end
    end

    let(:preprocessed_stream) do
      proc do |incremental_response, delta|
        stream_results << [incremental_response, delta]
      end
    end

    let(:response) do
      Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)).messages(
        parameters: {
          model: model,
          messages: messages,
          max_tokens: max_tokens,
          tools: tools,
          stream: stream
        }
      )
    end

    let(:preprocessed_response) do
      Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)).messages(
        parameters: {
          model: model,
          messages: messages,
          max_tokens: max_tokens,
          tools: tools,
          stream: preprocessed_stream,
          preprocess_stream: :text
        }
      )
    end

    let(:cassette) { "#{model} streaming tool use weather".downcase }

    context "with raw streaming" do
      it "succeeds and includes tool use" do
        VCR.use_cassette(cassette) do
          expect(response["content"].empty?).to eq(false)
          expect(chunks.length).to be > 0

          message_start = chunks.find { |chunk| chunk["type"] == "message_start" }
          expect(message_start).not_to be_nil
          expect(message_start["message"]["model"]).to eq(model)

          tool_use_start = chunks.find do |chunk|
            chunk["type"] == "content_block_start" && chunk["content_block"]["type"] == "tool_use"
          end
          expect(tool_use_start).not_to be_nil
          expect(tool_use_start["content_block"]["name"]).to eq("get_weather")

          input_json = chunks.select do |chunk|
                         chunk["type"] == "content_block_delta" && chunk["delta"]["type"] == "input_json_delta"
                       end
                             .map { |chunk| chunk["delta"]["partial_json"] }
                             .join
          expect(input_json).to include("location")
          expect(input_json).to include("San Francisco, CA")

          expect(chunks.any? { |chunk| chunk["type"] == "content_block_stop" }).to be true

          message_stop = chunks.find { |chunk| chunk["type"] == "message_delta" }
          expect(message_stop).not_to be_nil
          expect(message_stop["delta"]["stop_reason"]).to eq("tool_use")

          expect(chunks.last["type"]).to eq("message_stop")
        end
      end
    end

    context "with preprocessed streaming" do
      it "succeeds and includes tool use" do
        VCR.use_cassette("#{cassette}_preprocessed") do
          expect(preprocessed_response["content"].empty?).to eq(false)
          expect(stream_results.length).to be > 0

          combined_content = stream_results.map { |result| result[1].to_s }.join
          expect(combined_content).to include("San Francisco")
        end
      end
    end
  end
end
