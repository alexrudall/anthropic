module Anthropic
  module HTTPHeaders
    def add_headers(headers)
      @extra_headers = extra_headers.merge(headers.transform_keys(&:to_s))
    end

    private

    def headers
      # TODO: Implement Amazon Bedrock headers
      # if azure?
      #   azure_headers
      # else
      #   anthropic_headers
      # end.merge(extra_headers)
      anthropic_headers.merge(extra_headers)
    end

    def anthropic_headers
      {
        "x-api-key" => @access_token,
        "anthropic-version" => @anthropic_version,
        "Content-Type" => "application/json"
      }
    end

    # def azure_headers
    #   {
    #     "Content-Type" => "application/json",
    #     "api-key" => @access_token
    #   }
    # end

    def extra_headers
      @extra_headers ||= {}
    end
  end
end
