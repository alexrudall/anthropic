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

    context "streaming large preprocessed JSON" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:messages) do
        [
          {
            role: "user",
            content: <<~TXT.strip
              Give me 10 cool, large tweets about Ruby. Follow this format:

              [
                {
                  "title": "put tweet title here",
                  "tweet": "put tweet text here"
                }
              ]

              CRITICAL: Ensure JSON is valid. Escape all necessary characters.
              Don't output anything else, only JSON.
            TXT
          },
          {
            role: "assistant",
            content: ""
          }
        ]
      end
      let(:max_tokens) { 4096 }
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
          expect(response_objects.count).to eq(10)
          expect(response_objects).to eq(fixture_json("preprocessed_long_json.json"))
        end
      end
    end

    context "streaming empty preprocessed JSON array" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:messages) do
        [
          {
            role: "user",
            content: <<~TXT.strip
              Return this empty JSON array:

              []

              CRITICAL: Don't output anything else, only this empty JSON array.
            TXT
          },
          {
            role: "assistant",
            content: ""
          }
        ]
      end
      let(:max_tokens) { 4096 }
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
          expect(response_objects.count).to be(0)
          expect(response_objects).to eq([])
        end
      end
    end

    context "streaming preprocessed single small JSON object" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:messages) do
        [
          {
            role: "user",
            content: <<~TXT.strip
              Return this JSON object exactly as it is:

              {"name": "Mountain Name", "height": "height in km"}

              CRITICAL: Don't output anything else, only this JSON object.
            TXT
          },
          {
            role: "assistant",
            content: ""
          }
        ]
      end
      let(:max_tokens) { 4096 }
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
          expect(response_objects.count).to be(1)
          expect(response_objects)
            .to eq([{ "name" => "Mountain Name", "height" => "height in km" }])
        end
      end
    end

    context "streaming preprocessed single large JSON object" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:messages) do
        [
          {
            role: "user",
            content: <<~TXT.strip
              Return a single JSON object with a large text in the "text" field.
              The text should be at least 1000 characters long.

              {"text": "large text"}

              CRITICAL: Don't output anything else, only this JSON object.
            TXT
          },
          {
            role: "assistant",
            content: ""
          }
        ]
      end
      let(:max_tokens) { 4096 }
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
          expect(response_objects.count).to be(1)
          expect(response_objects)
            .to eq(fixture_json("preprocessed_single_long_json.json"))
        end
      end
    end

    context "preprocessing single empty JSON object" do
      let(:model) { "claude-3-haiku-20240307" }
      let(:messages) do
        [
          {
            role: "user",
            content: <<~TXT.strip
              Return this JSON object exactly as it is:

              {}

              CRITICAL: Don't output anything else, only this JSON object.
            TXT
          },
          {
            role: "assistant",
            content: ""
          }
        ]
      end
      let(:max_tokens) { 4096 }
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
          expect(response_objects.count).to be(1)
          expect(response_objects).to eq([{}])
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
          expect(response_objects.length).to be > 1 # One malformed object
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
