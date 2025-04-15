RSpec.describe Anthropic::Client do
  context "when using beta APIs" do
    let(:client) { Anthropic::Client.new.beta("message-batches-2024-09-24") }

    it "sends the appropriate header value" do
      expect(client.send(:headers)["anthropic-beta"]).to eq "message-batches-2024-09-24"
    end

    context "when chaining multiple betas" do
      let(:client) { Anthropic::Client.new.beta("feature1").beta("feature2") }

      it "maintains both beta values" do
        expect(client.send(:headers)["anthropic-beta"]).to eq "feature1,feature2"
      end
    end

    context "when using comma-separated betas" do
      let(:client) { Anthropic::Client.new.beta("feature1,feature2") }

      it "sends the combined header value" do
        expect(client.send(:headers)["anthropic-beta"]).to eq "feature1,feature2"
      end
    end
  end
end
