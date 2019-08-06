require 'telephony/twilio/programmable_api_client'

module Telephony
  module Twilio
    class ProgrammableSmsSender < ProgrammableApiClient
      def send(message:, to:)
        twilio_client.messages.create(
          messaging_service_sid: Telephony.config.twilio_messaging_service_sid,
          to: to,
          body: message,
        )
      rescue ::Twilio::REST::RestError => err
        handle_twilio_rest_error(err)
      end
    end
  end
end
