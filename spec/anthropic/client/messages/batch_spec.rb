RSpec.describe Anthropic::Client do
  let(:client) { Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)) }
  let(:json_prompt) { "Answer in the provided JSON format. Only include JSON." }

  describe "#messages.batch" do
    describe "#get" do
      context "#get batch messages" do
        let(:response) do
          Anthropic::Client.new(
            access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)
          ).messages.batch.get("msgbatch_01S2zP9e26DkVoocf8s6dqTm")
        end

        it "succeeds" do
          cassette = "batch_messages_get"
          VCR.use_cassette(cassette) do
            expect(response["id"].empty?).to eq(false)
          end
        end
      end
    end

    describe "#list" do
      context "#list batch messages" do
        let(:response) do
          Anthropic::Client.new(
            access_token: ENV.fetch("ANTHROPIC_API_KEY", nil)
          ).messages.batch.list
        end

        it "succeeds" do
          cassette = "batch_messages_list"
          VCR.use_cassette(cassette) do
            expect(response.empty?).to eq(false)
          end
        end
      end
    end

    describe "#results" do
      context "#results batch messages" do
        let(:response) do
          client = Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil))
          client.messages.batch.results("msgbatch_01668jySCZeCpMLsxFcroNnN")
        end

        it "succeeds" do
          cassette = "batch_messages_results"
          VCR.use_cassette(cassette) do
            expect(response.empty?).to eq(false)
          end
        end
      end
    end

    describe "#create" do
      context "#create batch messages" do
        let(:request1) do
          {
            custom_id: "first-prompt-in-my-batch",
            params: {
              model: "claude-3-haiku-20240307",
              max_tokens: 100,
              messages: [
                {
                  role: "user",
                  content: "Hey Claude, tell me a short fun fact about video games!"
                }
              ]
            }
          }
        end

        let(:request2) do
          {
            custom_id: "second-prompt-in-my-batch",
            params: {
              model: "claude-3-5-sonnet-20240620",
              max_tokens: 100,
              messages: [
                {
                  role: "user",
                  content: "Hey Claude, tell me a short fun fact about bees!"
                }
              ]
            }
          }
        end

        let(:response) do
          Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY",
                                                        nil)).messages.batch.create(
                                                          [request1, request2]
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

    describe "#cancel" do
      context "#cancel batch messages" do
        let(:response) do
          client = Anthropic::Client.new(access_token: ENV.fetch("ANTHROPIC_API_KEY", nil))
          client.messages.batch.cancel("msgbatch_015UrTAMKm5nXgAL7GRubKWB")
        end

        it "succeeds" do
          cassette = "batch_messages_cancel"
          VCR.use_cassette(cassette) do
            expect(response["processing_status"]).to eq("canceling")
          end
        end
      end
    end
  end
end
