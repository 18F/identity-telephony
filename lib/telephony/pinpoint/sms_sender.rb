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
          application_id: Telephony.config.pinpoint.sms.application_id,
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
                origination_number: Telephony.config.pinpoint.sms.shortcode,
              },
            },
          },
        )
        raise_if_error(response.message_response.result[to])
      end
      # rubocop:enable Metrics/MethodLength

      private

      def pinpoint_client
        credentials = AwsCredentialBuilder.new(:sms).call
        args = { region: Telephony.config.pinpoint.sms.region, retry_limit: 1 }
        args[:credentials] = credentials unless credentials.nil?
        @pinpoint_client ||= Aws::Pinpoint::Client.new(args)
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
