RSpec.describe Anthropic::Client do
  describe "#models" do
    describe "#list", :vcr do
      let(:response) { Anthropic::Client.new.models.list }
      let(:cassette) { "models list" }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response.dig("data", 0, "type")).to eq("model")
        end
      end

      context "with query params" do
        let(:response) { Anthropic::Client.new.models.list(query_params: { limit: 1 }) }
        let(:cassette) { "models list with limit" }

        it "succeeds" do
          VCR.use_cassette(cassette) do
            expect(response["data"].length).to eq(1)
          end
        end
      end
    end

    describe "#retrieve" do
      let(:cassette) { "models retrieve" }
      let(:response) { Anthropic::Client.new.models.retrieve(id: "claude-3-5-sonnet-20241022") }

      it "succeeds" do
        VCR.use_cassette(cassette) do
          expect(response["type"]).to eq("model")
        end
      end
    end
  end
end
