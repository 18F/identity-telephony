module Pinpoint
  class MockClient
    include ::RSpec::Matchers

    class << self
      attr_accessor :last_request
      attr_accessor :message_response_result_status_code
      attr_accessor :message_response_result_delivery_status

      def reset!
        self.last_request = nil
        self.message_response_result_status_code = 200
        self.message_response_result_delivery_status = 'SUCCESSFUL'
      end
    end

    Response = Struct.new(:message_response)
    MessageResponse = Struct.new(:result)
    MessageResponseResult = Struct.new(:status_code, :delivery_status)

    def send_messages(request)
      expect(request[:application_id]).to eq(Telephony.config.pinpoint.sms.application_id)

      self.class.last_request = request

      addresses = request.dig(:message_request, :addresses).keys
      expect(addresses.length).to eq(1)
      recipient_phone = addresses.first

      result_hash = {
        recipient_phone => MessageResponseResult.new(
          self.class.message_response_result_status_code,
          self.class.message_response_result_delivery_status,
        )
      }
      Response.new(MessageResponse.new(result_hash))
    end
  end
end
