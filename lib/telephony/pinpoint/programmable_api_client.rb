module Telephony
  module Pinpoint
    class ProgrammableApiClient
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

        error_hash = {
          'DUPLICATE' => DuplicateEndpointError,
          'OPT_OUT' => OptOutError,
          'PERMANENT_FAILURE' => PermanentFailureError,
          'TEMPORARY_FAILURE' => TemporaryFailureError,
          'THROTTLED' => ThrottledError,
          'TIMEOUT' => TimeoutError,
          'UNKNOWN_FAILURE' => UnknownFailureError,
        }
        exc = error_hash[response]
        raise exc, exception_message if exc
        raise TelephonyError, exception_message
      end
    end
  end
end
