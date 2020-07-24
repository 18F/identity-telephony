module Telephony
  module Twilio
    class ProgrammableApiClient
      def twilio_client
        @twilio_client ||= ::Twilio::REST::Client.new(
          Telephony.config.twilio.sid,
          Telephony.config.twilio.auth_token,
          nil,
          nil,
          http_client,
        )
      end

      def http_client
        @http_client ||= begin
          client = ::Twilio::HTTP::Client.new(timeout: Telephony.config.twilio.timeout.to_i)
          client.adapter = :net_http
          client
        end
      end

      def handle_twilio_rest_error(err)
        error_code = err.code
        error_message = err.message
        error_message = "Twilio REST API Error: #{error_code} - #{error_message}"
        error_class = error_class_for_code(error_code)
        error = error_class.new(error_message)
        Response.new(success: false, error: error)
      end

      # rubocop:disable Metrics/MethodLength
      def error_class_for_code(code)
        case code
        when 21_211
          InvalidPhoneNumberError
        when 21_614
          SmsUnsupportedError
        when 13_224
          VoiceUnsupportedError
        when 21_215
          InvalidCallingAreaError
        when 4_815_162_342
          ApiConnectionError
        else
          TelephonyError
        end
      end
      # rubocop:enable Metrics/MethodLength

      def handle_faraday_error(err)
        error = ApiConnectionError.new("Faraday error: #{err.class} - #{err.message}")
        Response.new(success: false, error: error)
      end
    end
  end
end
