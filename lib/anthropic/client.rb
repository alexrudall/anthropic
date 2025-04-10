require_relative "messages/batches"
require_relative "messages/client"

module Anthropic
  class Client
    include Anthropic::HTTP

    CONFIG_KEYS = %i[
      access_token
      anthropic_version
      api_version
      log_errors
      uri_base
      request_timeout
      extra_headers
    ].freeze
    attr_reader(*CONFIG_KEYS)

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
      log "[WARNING] Gem `anthropic` was renamed to `ruby-anthropic`.
        Please update your Gemfile to use `ruby-anthropic` version 0.4.2 or later."
    end

    # @deprecated (but still works while Anthropic API responds to it)
    def complete(parameters: {})
      parameters[:prompt] = wrap_prompt(prompt: parameters[:prompt])
      json_post(path: "/complete", parameters: parameters)
    end

    # Anthropic API Parameters as of 2024-05-07:
    # @see https://docs.anthropic.com/claude/reference/messages_post
    #
    # When called without parameters, returns a Messages::Batches instance for batch operations.
    # When called with parameters, creates a single message.
    #
    # @param [Hash] parameters
    # @option parameters [Array] :messages - Required. An array of messages to send to the API. Each
    #   message should have a role and content. Single message example:
    #   +[{ role: "user", content: "Hello, Claude!" }]+
    # @option parameters [String] :model - see https://docs.anthropic.com/claude/docs/models-overview
    # @option parameters [Integer] :max_tokens - Required, must be less than 4096 - @see https://docs.anthropic.com/claude/docs/models-overview
    # @option parameters [String] :system - Optional but recommended. @see https://docs.anthropic.com/claude/docs/system-prompts
    # @option parameters [Float] :temperature - Optional, defaults to 1.0
    # @option parameters [Proc] :stream - Optional, if present, must be a Proc that will receive the
    #   content fragments as they come in
    # @option parameters [String] :preprocess_stream - If true, the streaming Proc will be pre-
    #   processed. Specifically, instead of being passed a raw Hash like:
    #   {"type"=>"content_block_delta", "index"=>0, "delta"=>{"type"=>"text_delta", "text"=>" of"}}
    #   the Proc will instead be passed something nicer. If +preprocess_stream+ is set to +"json"+
    #   or +:json+, then the Proc will only receive full json objects, one at a time.
    #   If +preprocess_stream+ is set to +"text"+ or +:text+ then the Proc will receive two
    #   arguments: the first will be the text accrued so far, and the second will be the delta
    #   just received in the current chunk.
    #
    # @returns [Hash, Messages::Client] Returns a Hash response from the API when creating a message
    # with parameters, or a Messages::Client instance when called without parameters
    # @example Creating a message:
    #   {
    #     "id" => "msg_013xVudG9xjSvLGwPKMeVXzG",
    #     "type" => "message",
    #     "role" => "assistant",
    #     "content" => [{"type" => "text", "text" => "The sky has no distinct"}],
    #     "model" => "claude-2.1",
    #     "stop_reason" => "max_tokens",
    #     "stop_sequence" => nil,
    #     "usage" => {"input_tokens" => 15, "output_tokens" => 5}
    #   }
    # @example Accessing batches:
    #   client.messages.batches.create(requests: [...])
    #   client.messages.batches.get(id: "batch_123")
    def messages(**args)
      return @messages ||= Messages::Client.new(self) unless args && args[:parameters]

      json_post(path: "/messages", parameters: args[:parameters])
    end

    # Adds Anthropic beta features to API requests. Can be used in two ways:
    #
    # 1. Multiple betas in one call with comma-separated string:
    #    client.beta("feature1,feature2").messages
    #
    # 2. Chaining multiple beta calls:
    #    client.beta("feature1").beta("feature2").messages
    #
    # @param version [String] The beta version(s) to enable
    # @return [Client] A new client instance with the beta header(s)
    def beta(version)
      dup.tap do |client|
        existing_beta = client.extra_headers["anthropic-beta"]
        combined_beta = [existing_beta, version].compact.join(",")
        client.add_headers("anthropic-beta" => combined_beta)
      end
    end

    private

    # Used only by @deprecated +complete+ method
    def wrap_prompt(prompt:, prefix: "\n\nHuman: ", suffix: "\n\nAssistant:")
      return if prompt.nil?

      prompt.prepend(prefix) unless prompt.start_with?(prefix)
      prompt.concat(suffix) unless prompt.end_with?(suffix)
      prompt
    end
  end
end
