module Anthropic
  class Client
    extend Anthropic::HTTP

    CONFIG_KEYS = %i[
      access_token
      anthropic_version
      api_version
      uri_base
      request_timeout
      extra_headers
    ].freeze

    def initialize(config = {}, &faraday_middleware)
      CONFIG_KEYS.each do |key|
        # Set instance variables like api_type & access_token. Fall back to global config
        # if not present.
        instance_variable_set(
          "@#{key}",
          config[key].nil? ? Anthropic.configuration.send(key) : config[key]
        )
      end
      @faraday_middleware = faraday_middleware
    end

    def complete(parameters: {})
      parameters[:prompt] = wrap_prompt(prompt: parameters[:prompt])
      Anthropic::Client.json_post(path: "/complete", parameters: parameters)
    end

    def messages(parameters: {})
      Anthropic::Client.json_post(path: "/messages", parameters: parameters)
    end

    private

    def wrap_prompt(prompt:, prefix: "\n\nHuman: ", suffix: "\n\nAssistant:")
      return if prompt.nil?

      prompt.prepend(prefix) unless prompt.start_with?(prefix)
      prompt.concat(suffix) unless prompt.end_with?(suffix)
      prompt
    end
  end
end
