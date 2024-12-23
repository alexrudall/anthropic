module Anthropic
  class Models
    def initialize(client:)
      @client = client
    end

    # Anthropic API Parameters as of 2024-12-23:
    #   @see https://docs.anthropic.com/en/api/models-list
    # @param [Hash] query_params - The query parameters to pass to the API
    # @option query_params [String] :limit - The maximum number of models to return
    # @option query_params [String] :before_id - ID of the object to use as a cursor for pagination.
    #   When provided, returns the page of results immediately before this object.
    # @option query_params [String] :after_id - ID of the object to use as a cursor for pagination.
    #   When provided, returns the page of results immediately after this object.
    #
    # @returns [Hash] the response from the API
    #   @example:
    # {
    #   "data": [
    #     {
    #       "type": "model",
    #       "id": "claude-3-5-sonnet-20241022",
    #       "display_name": "Claude 3.5 Sonnet (New)",
    #       "created_at": "2024-10-22T00:00:00Z"
    #     }
    #   ]
    # }
    def list(query_params: {})
      @client.get(path: "/models", query_params: query_params)
    end

    # Anthropic API Parameters as of 2024-12-23:
    #   @see https://docs.anthropic.com/en/api/models
    # @param [String] id - The ID of the model to retrieve
    #
    # @returns [Hash] the response from the API
    #   @example:
    # {
    #   "type": "model",
    #   "id": "claude-3-5-sonnet-20241022",
    #   "display_name": "Claude 3.5 Sonnet (New)",
    #   "created_at": "2024-10-22T00:00:00Z"
    # }
    def retrieve(id:)
      @client.get(path: "/models/#{id}")
    end
  end
end
