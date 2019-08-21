module Telephony
  module Test
    class Call
      attr_reader :to, :body, :sent_at

      class << self
        def calls
          @calls ||= []
        end

        def clear_calls
          @calls = []
        end

        def last_otp(phone: nil)
          calls.reverse.find do |call|
            next false unless phone.nil? || call.to == phone

            true unless call.otp.nil?
          end&.otp
        end
      end

      def initialize(to:, body:, sent_at: Time.now)
        @to = to
        @body = body
        @sent_at = sent_at
      end

      def otp
        match = body.match(/(\d(\, )?){6}/)
        return match.to_s.gsub(', ', '') if match
      end
    end
  end
end
