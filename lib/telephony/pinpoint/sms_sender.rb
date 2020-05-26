module Telephony
  module Pinpoint
    class SmsSender
      ClientConfig = Struct.new(:client, :config)

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
        last_response = nil
        client_configs.each do |client_config|
          pinpoint_client = client_config.client
          sms_config = client_config.config

          pinpoint_response = pinpoint_client.send_messages(
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

          response = build_response(pinpoint_response)
          return response if response.success?
          notify_pinpoint_failover(response.error)
          last_response = response
        end
        last_response
      end
      # rubocop:enable Metrics/MethodLength

      # @api private
      # An array of (client, config) pairs
      # @return [Array<ClientConfig>]
      def client_configs
        @client_configs ||= Telephony.config.pinpoint.sms_configs.map do |sms_config|
          credentials = AwsCredentialBuilder.new(sms_config).call
          args = { region: sms_config.region, retry_limit: 1 }
          args[:credentials] = credentials unless credentials.nil?

          ClientConfig.new(
            build_client(args),
            sms_config
          )
        end
      end

      # @api private
      def build_client(args)
        Aws::Pinpoint::Client.new(args)
      end

      private

      # rubocop:disable Metrics/MethodLength
      def build_response(pinpoint_response)
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

      def notify_pinpoint_failover(error)
        # TODO: log some sort of message?
        Telephony.config.logger.warn "error region: region"
      end
    end
  end
end
