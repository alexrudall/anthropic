require "event_stream_parser"

require_relative "http_headers"

module Anthropic
  module HTTP
    def get(path:)
      to_json(conn.get(uri(path: path)) do |req|
        req.headers = headers
      end&.body)
    end

    def json_post(path:, parameters:)
      str_resp = {}
      response = conn.post(uri(path: path)) do |req|
        if parameters[:stream].is_a?(Proc)
          req.options.on_data = to_json_stream(user_proc: parameters[:stream], response: str_resp, preprocess: parameters[:preprocess_stream])
          parameters[:stream] = true # Necessary to tell Anthropic to stream.
        end

        req.headers = headers
        req.body = parameters.to_json
      end

      str_resp.empty? ? response.body : str_resp
    end

    def multipart_post(path:, parameters: nil)
      to_json(conn(multipart: true).post(uri(path: path)) do |req|
        req.headers = headers.merge({ "Content-Type" => "multipart/form-data" })
        req.body = multipart_parameters(parameters)
      end&.body)
    end

    def delete(path:)
      to_json(conn.delete(uri(path: path)) do |req|
        req.headers = headers
      end&.body)
    end

    private

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
    def to_json_stream(user_proc:, response:, preprocess: nil)
      parser = EventStreamParser::Parser.new

      preprocess_stack = ""

      proc do |chunk, _bytes, env|
        if env && env.status != 200
          raise_error = Faraday::Response::RaiseError.new
          raise_error.on_complete(env.merge(body: try_parse_json(chunk)))
        end

        parser.feed(chunk) do |type, data|
          parsed_data = JSON.parse(data)
          case type
          when "message_start"
            response.merge!(parsed_data["message"])
            response["content"] = [{ "type" => "text", "text" => "" }]
          when "message_delta"
            response["usage"].merge!(parsed_data["usage"])
            response.merge!(parsed_data["delta"])
          when "content_block_delta"
            delta = parsed_data["delta"]["text"]

            response["content"][0]["text"].concat(delta)

            unless preprocess.nil?
              preprocess_stack.concat(delta)
              if preprocess.to_sym == :json
                if preprocess_stack.strip.include?("}")
                  user_proc.call(JSON.parse(preprocess_stack.match(/\{(?:[^{}]|\g<0>)*\}/)[0]))
                  preprocess_stack = ""
                end
              elsif preprocess.to_sym == :text
                user_proc.call(preprocess_stack, delta)
              end
            end

          when "ping", "content_block_start"
            next
          end

          user_proc.call(parsed_data) unless data == "[DONE]" if preprocess.nil?
        end
      end
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

    def headers
      {
        "Content-Type" => "application/json",
        "x-api-key" => Anthropic.configuration.access_token,
        "Anthropic-Version" => Anthropic.configuration.anthropic_version
      }.merge(Anthropic.configuration.extra_headers)
    end

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

    def streaming?(parameters)
      parameters[:stream].is_a?(Proc)
    end
  end
end
