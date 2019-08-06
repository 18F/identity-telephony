module Telephony
  module Twilio
    class ProgrammableVoiceSender < ProgrammableApiClient
      def send(message:, to:)
        twilio_client.calls.create(
          from: from_number,
          to: to,
          url: callback_url_for_message(message),
          record: Telephony.config.twilio_record_voice,
        )
      rescue ::Twilio::REST::RestError => err
        handle_twilio_rest_error(err)
      end

      private

      def from_number
        Telephony.config.twilio_numbers.sample
      end

      def callback_url_for_message(message)
        ProgrammableVoiceMessage.new(message: message).callback_url
      end
    end
  end
end
