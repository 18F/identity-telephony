module Telephony
  module Pinpoint
    class VoiceSender
      ClientConfig = Struct.new(:client, :config)

      # rubocop:disable Metrics/MethodLength, Metrics::AbcSize
      def send(message:, to:)
        language_code, voice_id = language_code_and_voice_id

        last_error = nil
        client_configs.each do |client_config|
          begin
            response = client_config.client.send_voice_message(
              content: {
                plain_text_message: {
                  text: message,
                  language_code: language_code,
                  voice_id: voice_id,
                },
              },
              destination_phone_number: to,
              origination_phone_number: client_config.config.longcode_pool.sample,
            )
            return Response.new(
              success: true,
              error: nil,
              extra: { message_id: response.message_id }
            )
          rescue Aws::PinpointSMSVoice::Errors::ServiceError => e
            last_error = handle_pinpoint_error(e)
            notify_pinpoint_failover(e)
          end
        end
        last_error
      end
      # rubocop:enable Metrics/MethodLength, Metrics::AbcSize

      # @api private
      # An array of (client, config) pairs
      # @return [Array<ClientConfig>]
      def client_configs
        @client_configs ||= Telephony.config.pinpoint.voice_configs.map do |voice_config|
          credentials = AwsCredentialBuilder.new(voice_config).call
          args = { region: voice_config.region, retry_limit: 1 }
          args[:credentials] = credentials unless credentials.nil?

          ClientConfig.new(
            Aws::PinpointSMSVoice::Client.new(args),
            voice_config,
          )
        end
      end

      private

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

      def notify_pinpoint_failover(error)
        # TODO: log some sort of message?
        Telephony.config.logger.warn "error region: #{error}"
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
