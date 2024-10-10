module Anthropic
  class Batch
    def initialize(client)
      @client = client
    end

    # Anthropic API Parameters as of 2024-10-09:
    #   @see https://docs.anthropic.com/en/api/creating-message-batches
    #
    # @param [Array] :requests - List of requests for prompt completion. Each is an individual request to create a Message.
    #   Requests are an array of hashes, each with the following keys:
    #   - :custom_id (required): Developer-provided ID created for each request in a Message Batch.
    #                            Useful for matching results to requests, as results may be given out of request order.
    #                            Must be unique for each request within the Message Batch.
    #   - :params (required): Messages API creation parameters for the individual request.
    #                            See the Messages API reference for full documentation on available parameters.
    #
    # @returns [Hash] the response from the API (after the streaming is done, if streaming)
    #   @example:
    #
    # > messages.batch(requests_parameters)
    # {
    #   "id"=>"msgbatch_01668jySCZeCpMLsxFcroNnN",
    #   "type"=>"message_batch",
    #   "processing_status"=>"in_progress",
    #   "request_counts"=>{"processing"=>2, "succeeded"=>0, "errored"=>0, "canceled"=>0, "expired"=>0},
    #   "ended_at"=>nil,
    #   "created_at"=>"2024-10-09T20:18:11.480471+00:00",
    #   "expires_at"=>"2024-10-10T20:18:11.480471+00:00",
    #   "cancel_initiated_at"=>nil,
    #   "results_url"=>nil
    # }
    def batch(requests_parameters)
      custom_headers = { "anthropic-beta" => "message-batches-2024-09-24" }
      @client.json_post(path: "/messages/batches", parameters: { "requests" => requests_parameters }, custom_headers:)
    end
  end
end
