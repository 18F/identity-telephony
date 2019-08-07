module Telephony
  module Test
    class VoiceSender
      def send(message:, to:)
        Call.calls.push(Call.new(body: message, to: to))
      end
    end
  end
end
