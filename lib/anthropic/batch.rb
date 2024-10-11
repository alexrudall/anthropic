module Anthropic
  class MessagesBatcher
    def initialize(client)
      @client = client

      # Anthropic Batch API is in beta and requires a custom header
      @custom_headers = { "anthropic-beta" => "message-batches-2024-09-24" }
    end

    def batch
      Batcher.new(@client)
    end

    class Batcher < MessagesBatcher
      # Anthropic API Parameters as of 2024-10-09:
      #   @see https://docs.anthropic.com/en/api/creating-message-batches
      #
      # @param [Array] :requests - List of requests for prompt completion.
      #  Each is an individual request to create a Message.
      #  Requests are an array of hashes, each with the following keys:
      #  - :custom_id (required): Developer-provided ID created for each request in a Message Batch.
      #     Useful for matching results to requests, as results may be given out of request order.
      #     Must be unique for each request within the Message Batch.
      #  - :params (required): Messages API creation parameters for the individual request.
      #     See the Messages API reference for full documentation on available parameters.
      #
      # @returns [Hash] the response from the API (after the streaming is done, if streaming)
      #   @example:
      #
      # > messages.batch(requests_parameters)
      # {
      #   "id"=>"msgbatch_01668jySCZeCpMLsxFcroNnN",
      #   "type"=>"message_batch",
      #   "processing_status"=>"in_progress",
      #   "request_counts"=>{
      #     "processing"=>2,
      #     "succeeded"=>0,
      #     "errored"=>0,
      #     "canceled"=>0,
      #     "expired"=>0
      #   },
      #   "ended_at"=>nil,
      #   "created_at"=>"2024-10-09T20:18:11.480471+00:00",
      #   "expires_at"=>"2024-10-10T20:18:11.480471+00:00",
      #   "cancel_initiated_at"=>nil,
      #   "results_url"=>nil
      # }
      def create(requests_parameters)
        @client.json_post(
          path: "/messages/batches",
          parameters: { "requests" => requests_parameters },
          custom_headers: @custom_headers
        )
      end
    end

    # Anthropic API Parameters as of 2024-10-09:
    #   @see https://docs.anthropic.com/en/api/creating-message-batches
    #
    # @param Integer :id - ID of the Message Batch.
    #
    # @returns [Hash] the same response' shape as #create method.
    def get(id)
      @client.get(path: "/messages/batches/#{id}", custom_headers: @custom_headers)
    end

    # Anthropic API Parameters as of 2024-10-09:
    #   @see https://docs.anthropic.com/en/api/creating-message-batches
    #
    # @param Integer :id - ID of the Message Batch.
    #
    # Streams the results of a Message Batch as a .jsonl file.
    # Each line in the file is a JSON object containing the result of a
    # single request in the Message Batch.
    # Results are not guaranteed to be in the same order as requests.
    # Use the custom_id field to match results to requests.
    def results(id)
      @client.get(path: "/messages/batches/#{id}/results", custom_headers: @custom_headers,
                  jsonl: true)
    end

    # Anthropic API Parameters as of 2024-10-09:
    #   @see https://docs.anthropic.com/en/api/listing-message-batches
    #
    # List all Message Batches within a Workspace. Most recently created batches are returned first.
    # @param Integer :before_id - ID of the object to use as a cursor for pagination.
    #    When provided, returns the page of results immediately before this object.
    #
    # @param Integer :after_id - ID of the object to use as a cursor for pagination.
    #    When provided, returns the page of results immediately after this object.
    #
    # @param Integer :limit, Number of items to return per page.
    #   Defaults to 20. Ranges from 1 to 100.
    #
    # @returns [Hash] the response from the API
    def list(parameters: nil)
      @client.get(path: "/messages/batches", parameters: parameters,
                  custom_headers: @custom_headers)
    end

    # Anthropic API Parameters as of 2024-10-09:
    #   @see https://docs.anthropic.com/en/api/creating-message-batches
    #
    # @param Integer :id - ID of the Message Batch.
    #
    # @returns [Hash] the response from the API
    #
    # Cancel a Message Batch
    # Batches may be canceled any time before processing ends. Once cancellation is initiated,
    #   the batch enters a canceling state, at which time the system may complete any in-progress,
    #   non-interruptible requests before finalizing cancellation.
    #
    # The number of canceled requests is specified in request_counts.
    # To determine which requests were canceled, check the individual results within the batch.
    # Note that cancellation may not result in any canceled requests if they were non-interruptible.
    def cancel(id)
      @client.json_post(
        path: "/messages/batches/#{id}/cancel",
        parameters: {},
        custom_headers: @custom_headers
      )
    end
  end
end
