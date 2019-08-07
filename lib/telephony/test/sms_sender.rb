module Telephony
  module Test
    class SmsSender
      def send(message:, to:)
        Message.messages.push(Message.new(body: message, to: to))
      end
    end
  end
end
