module Anthropic
  class Client
    extend Anthropic::HTTP

    def initialize(access_token: nil, organization_id: nil, uri_base: nil, request_timeout: nil,
                   extra_headers: {})
      Anthropic.configuration.access_token = access_token if access_token
      Anthropic.configuration.organization_id = organization_id if organization_id
      Anthropic.configuration.uri_base = uri_base if uri_base
      Anthropic.configuration.request_timeout = request_timeout if request_timeout
      Anthropic.configuration.extra_headers = extra_headers
    end

    def completions(parameters: {})
      Anthropic::Client.json_post(path: "/completions", parameters: parameters)
    end
  end
end
