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
        @pinpoint_response = pinpoint_client.send_messages(
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
        response
      end
      # rubocop:enable Metrics/MethodLength

      private

      attr_reader :pinpoint_response

      def pinpoint_client
        credentials = AwsCredentialBuilder.new(:sms).call
        args = { region: Telephony.config.pinpoint.sms.region, retry_limit: 1 }
        args[:credentials] = credentials unless credentials.nil?
        @pinpoint_client ||= Aws::Pinpoint::Client.new(args)
      end

      # rubocop:disable Metrics/MethodLength
      def response
        Response.new(
          success: success?,
          error: error,
          extra: {
            request_id: pinpoint_response.message_response.request_id,
            delivery_status: message_response_result.delivery_status,
            message_id: message_response_result.message_id,
            status_code: message_response_result.status_code,
            status_message: message_response_result.status_message,
          },
        )
      end
      # rubocop:enable Metrics/MethodLength

      def success?
        @success ||= message_response_result.delivery_status == 'SUCCESSFUL'
      end

      def error
        return nil if success?

        @error ||= begin
          status_code = message_response_result.status_code
          delivery_status = message_response_result.delivery_status
          exception_message = "Pinpoint Error: #{delivery_status} - #{status_code}"
          exception_class = ERROR_HASH[delivery_status] || TelephonyError
          exception_class.new(exception_message)
        end
      end

      def message_response_result
        @message_repsonse ||= pinpoint_response.message_response.result.values.first
      end
    end
  end
end
