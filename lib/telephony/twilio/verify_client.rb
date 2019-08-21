require 'phonelib'
require 'typhoeus/adapters/faraday'

module Telephony
  module Twilio
    class VerifyClient
      AUTHY_HOST = 'https://api.authy.com'.freeze
      AUTHY_VERIFY_ENDPOINT = '/protected/json/phones/verification/start'.freeze

      attr_reader :otp, :recipient_number

      def send(otp:, to:)
        @otp = otp
        @recipient_number = to
        send_verify_request
      end

      private

      def send_verify_request
        return response if response.success?

        raise_bad_request_error
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => err
        raise_connection_timed_out_or_failed_error(err)
      end

      def response
        @response ||= http_client.post do |request|
          request.url AUTHY_VERIFY_ENDPOINT
          request.headers['X-Authy-API-Key'] = Telephony.config.twilio_verify_api_key
          request.body = request_body
        end
      end

      def request_body
        {
          code_length: otp.length,
          country_code: country_code,
          custom_code: otp,
          locale: I18n.locale,
          phone_number: number_without_country_code,
          via: :sms,
        }
      end

      def response_body
        @response_body ||= JSON.parse(response.body)
      rescue JSON::ParserError
        raise ApiConnectionError, 'Twilio Verify API response contained invalid JSON'
      end

      def raise_bad_request_error
        error_code = response_body.fetch('error_code', 0).to_i
        error_message = response_body.fetch('message', '')
        error_detail = "#{error_code} - #{error_message}"

        case error_code
        when 60_033, 60_078
          raise InvalidPhoneNumberError, "Twilio Verify Error: #{error_detail}"
        when 60_082
          raise SmsUnsupportedError, "Twilio Verify Error: #{error_detail}"
        when 60_083
          raise VoiceUnsupportedError, "Twilio Verify Error: #{error_detail}"
        else
          exception_message = "Twilio Verify API responded with #{response.status}: #{error_detail}"
          raise TelephonyError, exception_message
        end
      end

      def raise_connection_timed_out_or_failed_error(err)
        raise ApiConnectionError, "Verify API Error - #{err.class}"
      end

      def country_code
        parsed_phone.country_code
      end

      def number_without_country_code
        parsed_phone.raw_national
      end

      def parsed_phone
        @parsed_phone ||= Phonelib.parse(recipient_number)
      end

      def http_client
        @http_client ||= Faraday.new(
          url: AUTHY_HOST,
          request: { open_timeout: http_timeout, timeout: http_timeout }
        ) do |faraday|
          faraday.adapter :typhoeus
        end
      end

      def http_timeout
        @http_timeout ||= Telephony.config.twilio_timeout.to_i
      end
    end
  end
end
