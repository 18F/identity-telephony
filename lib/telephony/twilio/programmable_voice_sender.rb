module Telephony
  module Twilio
    class ProgrammableVoiceSender < ProgrammableApiClient
      def send(message:, to:)
        twilio_client.calls.create(
          from: from_number,
          to: to,
          url: callback_url_for_message(message),
          record: Telephony.config.twilio.record_voice,
        )
        Response.new(success: true)
      rescue ::Twilio::REST::RestError => e
        handle_twilio_rest_error(e)
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        handle_faraday_error(e)
      end

      private

      def from_number
        Telephony.config.twilio.numbers.sample
      end

      def callback_url_for_message(message)
        ProgrammableVoiceMessage.new(message: message).callback_url
      end
    end
  end
end
