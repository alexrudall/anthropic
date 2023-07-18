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
      parameters[:prompt] = wrap_prompt(prompt: parameters[:prompt])
      Anthropic::Client.json_post(path: "/complete", parameters: parameters)
    end

    private

    def wrap_prompt(prompt:, prefix: "\n\nHuman: ", suffix: "\n\nAssistant:")
      prompt.prepend(prefix) unless prompt.start_with?("\n\nHuman: ")
      prompt.concat(suffix) unless prompt.end_with?("\n\nAssistant:")
      prompt
    end
  end
end
