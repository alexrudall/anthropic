require "event_stream_parser"

require_relative "http_headers"

# rubocop:disable Metrics/ModuleLength
module Anthropic
  module HTTP
    include HTTPHeaders

    def get(path:, parameters: nil, custom_headers: {}, jsonl: false)
      response = conn.get(uri(path: path), parameters) do |req|
        req.headers = headers
        req.headers.merge!(custom_headers) if custom_headers.any?
      end

      jsonl ? to_json(response&.body) : response&.body
    end

    # This is currently the workhorse for all API calls.
    # rubocop:disable Metrics/MethodLength
    # rubocop:disable Metrics/AbcSize
    def json_post(path:, parameters:, custom_headers: {})
      str_resp = {}
      response = conn.post(uri(path: path)) do |req|
        if parameters.respond_to?(:key?) && parameters[:stream].is_a?(Proc)
          req.options.on_data = to_json_stream(user_proc: parameters[:stream], response: str_resp,
                                               preprocess: parameters[:preprocess_stream])
          parameters[:stream] = true # Necessary to tell Anthropic to stream.
          parameters.delete(:preprocess_stream)
        end

        req.headers = headers
        req.headers.merge!(custom_headers) if custom_headers.any?
        req.body = parameters.to_json
      end

      str_resp.empty? ? response.body : str_resp
    end
    # rubocop:enable Metrics/MethodLength
    # rubocop:enable Metrics/AbcSize

    # Unused?
    def multipart_post(path:, parameters: nil)
      to_json(conn(multipart: true).post(uri(path: path)) do |req|
        req.headers = headers.merge({ "Content-Type" => "multipart/form-data" })
        req.body = multipart_parameters(parameters)
      end&.body)
    end

    # Unused?
    def delete(path:)
      to_json(conn.delete(uri(path: path)) do |req|
        req.headers = headers
      end&.body)
    end

    private

    # Used only by unused methods?
    def to_json(string)
      return unless string

      JSON.parse(string)
    rescue JSON::ParserError
      # Convert a multiline string of JSON objects to a JSON array.
      JSON.parse(string.gsub("}\n{", "},{").prepend("[").concat("]"))
    end

    # Given a proc, returns an outer proc that can be used to iterate over a JSON stream of chunks.
    # For each chunk, the inner user_proc is called giving it the JSON object. The JSON object could
    # be a data object or an error object as described in the OpenAI API documentation.
    #
    # @param user_proc [Proc] The inner proc to call for each JSON object in the chunk.
    # @return [Proc] An outer proc that iterates over a raw stream, converting it to JSON.
    # rubocop:disable Metrics/MethodLength
    def to_json_stream(user_proc:, response:, preprocess: nil)
      parser = EventStreamParser::Parser.new
      preprocess_stack = ""

      proc do |chunk, _bytes, env|
        # Versions of Faraday < 2.5.0 do not include an `env` argument,
        # so we have to assume they are successful
        handle_faraday_error(chunk, env) if env

        parser.feed(chunk) do |type, data|
          parsed_data = JSON.parse(data)

          _handle_message_type(type, parsed_data, response) do |delta|
            preprocess(preprocess, preprocess_stack, delta, user_proc) unless preprocess.nil?
          end

          user_proc.call(parsed_data) if preprocess.nil?
        end
      end
    end
    # rubocop:enable Metrics/MethodLength

    # rubocop:disable Metrics/MethodLength
    def _handle_message_type(type, parsed_data, response, &block)
      case type
      when "message_start"
        response.merge!(parsed_data["message"])
        response["content"] = [{ "type" => "text", "text" => "" }]
      when "message_delta"
        response["usage"].merge!(parsed_data["usage"])
        response.merge!(parsed_data["delta"])
      when "content_block_delta"
        delta = parsed_data["delta"]["text"]
        response["content"][0]["text"].concat(delta) if delta
        block.yield delta
      end
    end
    # rubocop:enable Metrics/MethodLength

    # Decides whether to preprocess JSON or text and calls the appropriate method.
    def preprocess(directive, stack, delta, user_proc)
      stack.concat(delta) if delta # Alters the stack.
      case directive
      when :json
        preprocess_json(stack, delta, user_proc)
      when :text
        preprocess_text(stack, delta, user_proc)
      else
        raise Anthropic::Error,
              "Invalid preprocess directive (valid: :text, :json): #{directive.inspect}"
      end
    end

    # Just sends the incremental response (aka stack) and delta up to the user
    def preprocess_text(stack, delta, user_proc)
      user_proc.call(stack, delta)
    end

    # If the stack contains a +}+, uses a regexp to try to find a complete JSON object.
    # If it finds one, it calls the user_proc with the JSON object. If it fails, catches and logs
    # an exception but does not currently raise it, which means that if there is just one malformed
    # JSON object (which does happen, albeit rarely), it will continue and process the other ones.
    #
    # TODO: Make the exception processing parametrisable (set logger? exit on error?)
    def preprocess_json(stack, _delta, user_proc)
      if stack.strip.include?("}")
        matches = stack.match(/\{(?:[^{}]|\g<0>)*\}/)
        user_proc.call(JSON.parse(matches[0]))
        stack.clear
      end
    rescue StandardError => e
      log(e)
    ensure
      stack.clear if stack.strip.include?("}")
    end

    def log(error)
      logger = Logger.new($stdout)
      logger.formatter = proc do |_severity, _datetime, _progname, msg|
        "\033[31mAnthropic JSON Error (spotted in ruby-anthropic #{VERSION}): #{msg}\n\033[0m"
      end
      logger.error(error)
    end

    def handle_faraday_error(chunk, env)
      return unless env&.status != 200

      raise_error = Faraday::Response::RaiseError.new
      raise_error.on_complete(env.merge(body: try_parse_json(chunk)))
    end

    def conn(multipart: false)
      connection = Faraday.new do |f|
        f.options[:timeout] = @request_timeout
        f.request(:multipart) if multipart
        f.use MiddlewareErrors if @log_errors
        f.response :raise_error
        f.response :json
      end

      @faraday_middleware&.call(connection)

      connection
    end

    def uri(path:)
      Anthropic.configuration.uri_base + Anthropic.configuration.api_version + path
    end

    # Unused except by unused method
    def multipart_parameters(parameters)
      parameters&.transform_values do |value|
        next value unless value.is_a?(File)

        # Doesn't seem like Anthropic needs mime_type yet, so not worth
        # the library to figure this out. Hence the empty string
        # as the second argument.
        Faraday::UploadIO.new(value, "", value.path)
      end
    end

    def try_parse_json(maybe_json)
      JSON.parse(maybe_json)
    rescue JSON::ParserError
      maybe_json
    end
  end
end
# rubocop:enable Metrics/ModuleLength
