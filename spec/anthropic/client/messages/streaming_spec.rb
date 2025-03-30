RSpec.describe Anthropic::Client do
  let(:json_prompt) { "Answer in the provided JSON format. Only include JSON." }

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
          expect(chunks.length).to be > 0
        end
      end
    end

    context "preprocessed streaming" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:messages) { [{ role: "user", content: "How high is the sky?" }] }
      let(:max_tokens) { 50 }
      let(:stream_results) { [] }

      let(:stream) do
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
            stream: stream,
            preprocess_stream: :text
          }
        )
      end

      let(:cassette) { "#{model} streaming #{messages[0][:content]}".downcase }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["content"].empty?).to eq(false)
          expect(stream_results.last[0]).to include("sky")
        end
      end
    end

    context "streaming JSON" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:messages) do
        [{ role: "user", content: "Give me the height of the 3 tallest mountains. #{json_prompt}" },
         { role: "assistant",
           content: '[{"name": "Mountain Name", "height": "height in km"}]' }]
      end
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
          expect(chunks.length).to be > 0
        end
      end
    end

    context "streaming preprocessed JSON" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:messages) do
        [{ role: "user", content: "Give me the height of the 3 tallest mountains. #{json_prompt}" },
         { role: "assistant",
           content: '[{"name": "Mountain Name", "height": "height in km"}]' }]
      end
      let(:max_tokens) { 200 }
      let(:response_objects) { [] }

      let(:stream) do
        proc do |json_object|
          response_objects << json_object
        end
      end

      let(:response) do
        Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)).messages(
          parameters: {
            model: model,
            messages: messages,
            max_tokens: max_tokens,
            stream: stream,
            preprocess_stream: :json
          }
        )
      end

      let(:cassette) { "#{model} streaming json #{messages[0][:content]}".downcase }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["content"].empty?).to eq(false)
          expect(response_objects.length > 1).to eq(true)
          expect(response_objects[0]["name"]).to eq("Mount Everest")
        end
      end
    end

    context "malformed streaming preprocessed JSON" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:messages) do
        [{ role: "user", content: "Give me the height of the 3 tallest mountains. #{json_prompt}" },
         { role: "assistant",
           content: '[{"name": "Mountain Name", "height": "height in km"}]' }]
      end
      let(:max_tokens) { 200 }
      let(:response_objects) { [] }

      let(:stream) do
        proc do |json_object|
          response_objects << json_object
        end
      end

      let(:response) do
        Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)).messages(
          parameters: {
            model: model,
            messages: messages,
            max_tokens: max_tokens,
            stream: stream,
            preprocess_stream: :json
          }
        )
      end

      let(:cassette) { "#{model} malformed streaming json #{messages[0][:content]}".downcase }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["content"].empty?).to eq(false)
          expect(response_objects.length).to be >= 1 # One malformed object
          expect(response_objects[0]["name"]).to eq("Mount Everest")
        end
      end
    end

    context "with all required parameters (:model, :messages, :max_tokens)" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:data)  { Marshal.load(File.binread("#{Dir.pwd}/spec/fixtures/image_base64")) }
      let(:source) { { type: "base64", media_type: "image/png", data: data } }
      let(:messages) do
        [{ role: "user",
           content: [{ type: "image", source: source }, { type: "text", text: "What is this" }] }]
      end
      let(:max_tokens) { 50 }

      let(:response) do
        Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)).messages(
          parameters: {
            model: model,
            messages: messages,
            max_tokens: max_tokens
          }
        )
      end

      let(:cassette) { "#{model} vision #{messages[0][:content][1][:text]}".downcase }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["content"].empty?).to eq(false) # Response should still be false!
        end
      end
    end
  end
end
