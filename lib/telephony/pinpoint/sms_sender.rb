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

      # rubocop:disable Metrics/MethodLength
      def send(message:, to:)
        response = pinpoint_client.send_messages(
          application_id: Telephony.config.pinpoint_application_id,
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
                origination_number: origination_number,
              },
            },
          },
        )
        raise_if_error(response.message_response.result[to])
      end
      # rubocop:enable Metrics/MethodLength

      protected

      def origination_number
        Telephony.config.pinpoint_shortcode
      end

      private

      def pinpoint_client
        @pinpoint_client ||= Aws::Pinpoint::Client.new(
          region: Telephony.config.pinpoint_region,
          access_key_id: Telephony.config.pinpoint_access_key_id,
          secret_access_key: Telephony.config.pinpoint_secret_access_key,
        )
      end

      def raise_if_error(response)
        status_code = response.status_code
        delivery_status = response.delivery_status
        return true if delivery_status == 'SUCCESSFUL'
        exception_message = "Pinpoint Error: #{delivery_status} - #{status_code}"
        exc = ERROR_HASH[delivery_status]
        raise exc, exception_message if exc
        raise TelephonyError, exception_message
      end
    end
  end
end
