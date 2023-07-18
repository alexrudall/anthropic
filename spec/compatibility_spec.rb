RSpec.describe "compatibility" do
  context "for moved constants" do
    describe "::Ruby::Anthropic::VERSION" do
      it "is mapped to ::Anthropic::VERSION" do
        expect(Ruby::Anthropic::VERSION).to eq(Anthropic::VERSION)
      end
    end

    describe "::Ruby::Anthropic::Error" do
      it "is mapped to ::Anthropic::Error" do
        expect(Ruby::Anthropic::Error).to eq(Anthropic::Error)
        expect(Ruby::Anthropic::Error.new).to be_a(Anthropic::Error)
        expect(Anthropic::Error.new).to be_a(Ruby::Anthropic::Error)
      end
    end

    describe "::Ruby::Anthropic::ConfigurationError" do
      it "is mapped to ::Anthropic::ConfigurationError" do
        expect(Ruby::Anthropic::ConfigurationError).to eq(Anthropic::ConfigurationError)
        expect(Ruby::Anthropic::ConfigurationError.new).to be_a(Anthropic::ConfigurationError)
        expect(Anthropic::ConfigurationError.new).to be_a(Ruby::Anthropic::ConfigurationError)
      end
    end

    describe "::Ruby::Anthropic::Configuration" do
      it "is mapped to ::Anthropic::Configuration" do
        expect(Ruby::Anthropic::Configuration).to eq(Anthropic::Configuration)
        expect(Ruby::Anthropic::Configuration.new).to be_a(Anthropic::Configuration)
        expect(Anthropic::Configuration.new).to be_a(Ruby::Anthropic::Configuration)
      end
    end
  end
end
