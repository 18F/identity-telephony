require 'telephony/util'
require 'time'

module Telephony
  module Pinpoint
    class SmsSender
      ERROR_HASH = {
        'DUPLICATE' => DuplicateEndpointError,
        'OPT_OUT' => OptOutError,
        'PERMANENT_FAILURE' => PermanentFailureError,
        'TEMPORARY_FAILURE' => TemporaryFailureError,
        'THROTTLED' => ThrottledError,
        'TIMEOUT' => TimeoutError,
        'UNKNOWN_FAILURE' => UnknownFailureError,
      }.freeze

      # rubocop:disable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength
      # @return [Response]
      def send(message:, to:)
        response = nil
        Telephony.config.pinpoint.sms_configs.each do |sms_config|
          start = Time.now
          pinpoint_response = build_client(sms_config).send_messages(
            application_id: sms_config.application_id,
            message_request: {
              addresses: {
                to => {
                  channel_type: 'SMS',
                },
              },
              message_configuration: {
                sms_message: {
                  body: message,
                  message_type: 'TRANSACTIONAL',
                  origination_number: sms_config.shortcode,
                },
              },
            },
          )
          finish = Time.now
          response = build_response(pinpoint_response, start: start, finish: finish)
          return response if response.success?
          notify_pinpoint_failover(
            error: response.error,
            region: sms_config.region,
            extra: response.extra,
          )
        rescue Seahorse::Client::NetworkingError => e
          finish = Time.now
          response = handle_pinpoint_error(e)
          notify_pinpoint_failover(
            error: e,
            region: sms_config.region,
            extra: {
              duration_ms: Util.duration_ms(start: start, finish: finish),
            },
          )
        end
        response
      end
      # rubocop:enable Metrics/MethodLength, Metrics/AbcSize, Metrics/BlockLength


      def phone_info(phone_number)
        response = nil
        error = nil

        Telephony.config.pinpoint.sms_configs.each do |sms_config|
          error = nil
          response = build_client(sms_config).phone_number_validate(
            number_validate_request: { phone_number: phone_number }
          )
          break if response
        rescue Seahorse::Client::NetworkingError => error
          notify_pinpoint_failover(
            error: error,
            region: sms_config.region,
            extra: {},
          )
        end

        type = case response&.number_validate_response&.phone_type
        when 'MOBILE'
          :mobile
        when 'LANDLINE'
          :landline
        when 'VOIP'
          :voip
        else
          :unknown
        end

        PhoneNumberInfo.new(
          type: type,
          carrier: response&.number_validate_response&.carrier,
          error: error,
        )
      end

      # @api private
      # @param [PinpointSmsConfig] sms_config
      def build_client(sms_config)
        args = { region: sms_config.region, retry_limit: 0 }

        credentials = AwsCredentialBuilder.new(sms_config).call
        args[:credentials] = credentials if credentials

        Aws::Pinpoint::Client.new(args)
      end

      private

      def handle_pinpoint_error(err)
        error_message = "#{err.class}: #{err.message}"

        Response.new(
          success: false, error: Telephony::TelephonyError.new(error_message),
        )
      end

      # rubocop:disable Metrics/MethodLength
      def build_response(pinpoint_response, start:, finish:)
        message_response_result = pinpoint_response.message_response.result.values.first

        Response.new(
          success: success?(message_response_result),
          error: error(message_response_result),
          extra: {
            request_id: pinpoint_response.message_response.request_id,
            delivery_status: message_response_result.delivery_status,
            message_id: message_response_result.message_id,
            status_code: message_response_result.status_code,
            status_message: message_response_result.status_message,
            duration_ms: Util.duration_ms(start: start, finish: finish),
          },
        )
      end
      # rubocop:enable Metrics/MethodLength

      def success?(message_response_result)
        message_response_result.delivery_status == 'SUCCESSFUL'
      end

      def error(message_response_result)
        return nil if success?(message_response_result)

        status_code = message_response_result.status_code
        delivery_status = message_response_result.delivery_status
        exception_message = "Pinpoint Error: #{delivery_status} - #{status_code}"
        exception_class = ERROR_HASH[delivery_status] || TelephonyError
        exception_class.new(exception_message)
      end

      def notify_pinpoint_failover(error:, region:, extra:)
        response = Response.new(
          success: false,
          error: error,
          extra: extra.merge(
            failover: true,
            region: region,
            channel: 'sms',
          ),
        )
        Telephony.config.logger.warn(response.to_h.to_json)
      end
    end
  end
end
