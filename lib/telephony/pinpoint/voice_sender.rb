module Telephony
  module Pinpoint
    class VoiceSender
      # rubocop:disable Metrics/MethodLength
      def send(message:, to:)
        language_code, voice_id = language_code_and_voice_id
        pinpoint_client.send_voice_message(
          content: {
            plain_text_message: {
              text: message,
              language_code: language_code,
              voice_id: voice_id,
            },
          },
          destination_phone_number: to,
          origination_phone_number: Telephony.config.pinpoint_longcode_pool.sample,
        )
      rescue Aws::PinpointSMSVoice::Errors::ServiceError => e
        handle_pinpoint_error(e)
      end
      # rubocop:enable Metrics/MethodLength

      private

      def pinpoint_client
        @pinpoint_client ||= Aws::PinpointSMSVoice::Client.new(
          region: Telephony.config.pinpoint_region,
          access_key_id: Telephony.config.pinpoint_access_key_id,
          secret_access_key: Telephony.config.pinpoint_secret_access_key,
        )
      end

      def handle_pinpoint_error(err)
        error_message = "#{err.class}: #{err.message}"
        if err.is_a? Aws::PinpointSMSVoice::Errors::LimitExceededException
          raise Telephony::ThrottledError, error_message
        end
        raise Telephony::TelephonyError, error_message
      end

      def language_code_and_voice_id
        case I18n.locale.to_sym
        when :en
          ['en-US', 'Joey']
        when :fr
          ['fr-FR', 'Mathieu']
        when :es
          ['es-US', 'Miguel']
        else
          ['en-US', 'Joey']
        end
      end
    end
  end
end
