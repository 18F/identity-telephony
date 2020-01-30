module Telephony
  module Pinpoint
    class VoiceSender
      # rubocop:disable Metrics/MethodLength
      def send(message:, to:)
        language_code, voice_id = language_code_and_voice_id
        response = pinpoint_client.send_voice_message(
          content: {
            plain_text_message: {
              text: message,
              language_code: language_code,
              voice_id: voice_id,
            },
          },
          destination_phone_number: to,
          origination_phone_number: Telephony.config.pinpoint.voice.longcode_pool.sample,
        )
        Response.new(success: true, error: nil, extra: { message_id: response.message_id })
      rescue Aws::PinpointSMSVoice::Errors::ServiceError => e
        handle_pinpoint_error(e)
      end
      # rubocop:enable Metrics/MethodLength

      private

      def pinpoint_client
        credentials = AwsCredentialBuilder.new(:voice).call
        args = { region: Telephony.config.pinpoint.voice.region, retry_limit: 1 }
        args[:credentials] = credentials unless credentials.nil?
        @pinpoint_client ||= Aws::PinpointSMSVoice::Client.new(args)
      end

      def handle_pinpoint_error(err)
        request_id = err.context&.metadata&.fetch(:request_id, nil)

        error_message = "#{err.class}: #{err.message}"
        error_class = if err.is_a? Aws::PinpointSMSVoice::Errors::LimitExceededException
                        Telephony::ThrottledError
                      else
                        Telephony::TelephonyError
                      end

        Response.new(
          success: false, error: error_class.new(error_message), extra: { request_id: request_id },
        )
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
