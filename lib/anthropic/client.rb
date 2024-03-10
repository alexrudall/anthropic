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

    def complete(parameters: {})
      parameters[:prompt] = wrap_prompt(prompt: parameters[:prompt])
      Anthropic::Client.json_post(path: "/complete", parameters: parameters)
    end

      def messages(model:, messages:, system: nil, parameters: {}) # rubocop:disable Metrics/MethodLength
      parameters.merge!(system: system) if system
      parameters.merge!(model: model, messages: messages)

      max_attempts = 5
      attempts = 0

      # TODO: does this level of retry implementation belong here?
      loop do
        attempts += 1
        Anthropic::Client.json_post(path: "/messages", parameters: parameters).tap do |response|
          # handle successful response
          return response if response.dig("content", 0, "text")

          # handle max attempts
          if attempts > max_attempts
            raise Anthropic::Error,
                  "Failed after #{max_attempts} attempts. #{error_message}"
          end

          # handle error response
          error_type = response.dig("error", "type")
          error_message = response.dig("error", "message")
          if %w[overloaded_error api_error rate_limit_error].include?(error_type) # rubocop:disable Style/GuardClause
            # retry loop with exponential backoff
            sleep(1 * attempts)
          else
            raise Anthropic::Error, error_message
          end
        end
      end
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
