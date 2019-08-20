require 'telephony/pinpoint/programmable_api_client'

module Telephony
  module Pinpoint
    class ProgrammableSmsSender < ProgrammableApiClient
      def send(message:, to:)
        response = pinpoint_client.send_messages(
          {
            application_id: Telephony.config.pinpoint_application_id,
            message_request:
              {
                addresses:
                  {
                    to =>
                      {
                        channel_type: 'SMS',
                      },
                  },
                message_configuration:
                  {
                    sms_message:
                      {
                        body: message,
                        message_type: 'TRANSACTIONAL',
                      },
                  },
              },
          })
        raise_if_error(response.message_response.result[to])
      end
    end
  end
end
