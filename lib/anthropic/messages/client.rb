module Anthropic
  module Messages
    class Client
      def initialize(client)
        @client = client
      end

      def batches
        @batches ||= Batches.new(@client)
      end
    end
  end
end
