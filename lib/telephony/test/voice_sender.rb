module Telephony
  module Test
    class VoiceSender
      def send(message:, to:)
        Call.calls.push(Call.new(body: message, to: to))
        Response.new(success: true, extra: { request_id: 'fake-message-request-id' })
      end
    end
  end
end
