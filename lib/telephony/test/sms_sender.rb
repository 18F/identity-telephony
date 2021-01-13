module Telephony
  module Test
    class SmsSender
      def send(message:, to:)
        error = ErrorSimulator.new.error_for_number(to)
        if error.nil?
          Message.messages.push(Message.new(body: message, to: to))
          success_response
        else
          Response.new(
            success: false, error: error, extra: { request_id: 'fake-message-request-id' },
          )
        end
      end

      def voip_phone?(phone_number)
        !!ErrorSimulator.new.error_for_number(phone_number)
      end

      def success_response
        Response.new(
          success: true,
          extra: { request_id: 'fake-message-request-id', message_id: 'fake-message-id' },
        )
      end
    end
  end
end