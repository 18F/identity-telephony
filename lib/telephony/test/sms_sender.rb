module Telephony
  module Test
    class SmsSender
      def send(message:, to:)
        Message.messages.push(Message.new(body: message, to: to))
        Response.new(success: true, extra: { request_id: 'fake-message-request-id' })
      end
    end
  end
end
