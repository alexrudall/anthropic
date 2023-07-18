RSpec.describe Anthropic do
  it "has a version number" do
    expect(Anthropic::VERSION).not_to be nil
  end

  describe "#configure" do
    let(:access_token) { "abc123" }
    let(:api_version) { "v2" }
    let(:organization_id) { "def456" }
    let(:custom_uri_base) { "ghi789" }
    let(:custom_request_timeout) { 25 }
    let(:extra_headers) { { "User-Agent" => "Anthropic Ruby Gem #{Anthropic::VERSION}" } }

    before do
      Anthropic.configure do |config|
        config.access_token = access_token
        config.api_version = api_version
        config.organization_id = organization_id
        config.extra_headers = extra_headers
      end
    end

    it "returns the config" do
      expect(Anthropic.configuration.access_token).to eq(access_token)
      expect(Anthropic.configuration.api_version).to eq(api_version)
      expect(Anthropic.configuration.organization_id).to eq(organization_id)
      expect(Anthropic.configuration.uri_base).to eq("https://api.anthropic.com/")
      expect(Anthropic.configuration.request_timeout).to eq(120)
      expect(Anthropic.configuration.extra_headers).to eq(extra_headers)
    end

    context "without an access token" do
      let(:access_token) { nil }

      it "raises an error" do
        expect { Anthropic::Client.new.completions }.to raise_error(Anthropic::ConfigurationError)
      end
    end

    context "with custom timeout and uri base" do
      before do
        Anthropic.configure do |config|
          config.uri_base = custom_uri_base
          config.request_timeout = custom_request_timeout
        end
      end

      it "returns the config" do
        expect(Anthropic.configuration.access_token).to eq(access_token)
        expect(Anthropic.configuration.api_version).to eq(api_version)
        expect(Anthropic.configuration.organization_id).to eq(organization_id)
        expect(Anthropic.configuration.uri_base).to eq(custom_uri_base)
        expect(Anthropic.configuration.request_timeout).to eq(custom_request_timeout)
        expect(Anthropic.configuration.extra_headers).to eq(extra_headers)
      end
    end
  end
end
