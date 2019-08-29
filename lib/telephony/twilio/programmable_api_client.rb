require 'typhoeus/adapters/faraday'

module Telephony
  module Twilio
    class ProgrammableApiClient
      def twilio_client
        @twilio_client ||= ::Twilio::REST::Client.new(
          Telephony.config.twilio_sid,
          Telephony.config.twilio_auth_token,
          nil,
          nil,
          http_client,
        )
      end

      def http_client
        @http_client ||= begin
          client = ::Twilio::HTTP::Client.new(timeout: Telephony.config.twilio_timeout.to_i)
          client.adapter = :typhoeus
          client
        end
      end

      # rubocop:disable Metrics/MethodLength
      def handle_twilio_rest_error(err)
        error_code = err.code
        error_message = err.message
        exception_message = "Twilio REST API Error: #{error_code} - #{error_message}"

        case error_code
        when 21_211
          raise InvalidPhoneNumberError, exception_message
        when 21_614
          raise SmsUnsupportedError, exception_message
        when 13_224
          raise VoiceUnsupportedError, exception_message
        when 21_215
          raise InvalidCallingAreaError, exception_message
        when 4_815_162_342
          raise ApiConnectionError, exception_message
        else
          raise TelephonyError, exception_message
        end
      end
      # rubocop:enable Metrics/MethodLength

      def handle_faraday_error(err)
        raise ApiConnectionError, "Faraday error: #{err.class} - #{err.message}"
      end
    end
  end
end
