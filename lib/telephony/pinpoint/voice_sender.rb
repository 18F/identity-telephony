require 'pry-byebug'

require 'telephony/pinpoint/api_client'

module Telephony
  module Pinpoint
    class VoiceSender < ApiClient
      # rubocop:disable Metrics/MethodLength
      def send(message:, to:)
        response = pinpoint_client.send_messages(
          application_id: Telephony.config.pinpoint_application_id,
          message_request: {
            addresses: {
              to => {
                channel_type: 'VOICE',
              },
            },
            message_configuration: {
              voice_message: {
                body: message,
              },
            },
          },
        )
        raise_if_error(response.message_response.result[to])
      end
      # rubocop:enable Metrics/MethodLength
    end
  end
end
