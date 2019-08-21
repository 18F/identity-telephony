require 'telephony/pinpoint/programmable_api_client'

module Telephony
  module Pinpoint
    class ProgrammableVoiceSender < ProgrammableApiClient
      def send(message:, to:)
        response = pinpoint_client.send_messages(
          {
            application_id: pinpoint_application_id,
            message_request:
              {
                addresses:
                  {
                    to =>
                      {
                        channel_type: 'VOICE',
                      },
                  },
                message_configuration:
                  {
                    voice_message:
                      {
                        body: message,
                      },
                  },
              },
          }
        )
        raise_if_error(response.message_response.result[to])
      end
    end
  end
end
