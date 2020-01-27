module Telephony
  module Test
    class SmsSender
      def send(message:, to:)
        error = ErrorSimulator.new.error_for_number(to)
        if error.nil?
          Message.messages.push(Message.new(body: message, to: to))
          Response.new(success: true, extra: { request_id: 'fake-message-request-id' })
        else
          Response.new(success: false, error: error, extra: { request_id: 'fake-message-request-id' })
        end
      end
    end
  end
end
