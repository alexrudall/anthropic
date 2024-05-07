RSpec.describe Anthropic::Client do
  describe "#messages" do
    context "with all required parameters (:model, :messages, :max_tokens)" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:messages) { [{ role: "user", content: "How high is the sky?" }] }
      let(:max_tokens) { 5 }

      let(:response) do
        Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)).messages(
          parameters: {
            model: model,
            messages: messages,
            max_tokens: max_tokens
          }
        )
      end

      let(:cassette) { "#{model} messages #{messages[0][:content]}".downcase }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["content"].empty?).to eq(false) # Response should still be false!
        end
      end
    end

    context "streaming" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:messages) { [{ role: "user", content: "How high is the sky?" }] }
      let(:max_tokens) { 50 }
      let(:chunks) { [] }

      let(:stream) do
        proc do |chunk|
          chunks << chunk
        end
      end

      let(:response) do
        Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)).messages(
          parameters: {
            model: model,
            messages: messages,
            max_tokens: max_tokens,
            stream: stream
          }
        )
      end

      let(:cassette) { "#{model} streaming #{messages[0][:content]}".downcase }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["content"].empty?).to eq(false)
          expect(chunks.length).to eq(53)
        end
      end
    end


    context "streaming JSON" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:messages) { [{ role: "user", content: "Give me the heights of the 3 tallest mountains. Answer in the provided JSON format. Only include JSON." },
                        { role: "assistant", content: '[{"name": "Mountain Name", "height": "height in km"}]' }] }
      let(:max_tokens) { 200 }
      let(:chunks) { [] }

      let(:stream) do
        proc do |chunk|
          chunks << chunk
        end
      end

      let(:response) do
        Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)).messages(
          parameters: {
            model: model,
            messages: messages,
            max_tokens: max_tokens,
            stream: stream
          }
        )
      end

      let(:cassette) { "#{model} streaming json #{messages[0][:content]}".downcase }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["content"].empty?).to eq(false)
          expect(chunks.length).to eq(71)
        end
      end
    end
  end
end
