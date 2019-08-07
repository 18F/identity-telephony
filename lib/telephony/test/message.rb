module Telephony
  module Test
    class Message
      attr_reader :to, :body, :sent_at

      class << self
        def messages
          @messages ||= []
        end

        def clear_messages
          @messages = []
        end

        def last_otp(phone: nil)
          messages.reverse.find do |messages|
            next false unless phone.nil? || messages.to == phone
            true unless messages.otp.nil?
          end&.otp
        end
      end

      def initialize(to:, body:, sent_at: Time.now)
        @to = to
        @body = body
        @sent_at = sent_at
      end

      def otp
        match = body.match(/\d{6}/)
        return match.to_s if match
      end
    end
  end
end
