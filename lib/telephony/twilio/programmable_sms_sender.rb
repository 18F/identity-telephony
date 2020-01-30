require 'telephony/twilio/programmable_api_client'

module Telephony
  module Twilio
    class ProgrammableSmsSender < ProgrammableApiClient
      def send(message:, to:)
        twilio_client.messages.create(
          messaging_service_sid: Telephony.config.twilio.messaging_service_sid,
          to: to,
          body: message,
        )
        Response.new(success: true)
      rescue ::Twilio::REST::RestError => e
        handle_twilio_rest_error(e)
      rescue Faraday::TimeoutError, Faraday::ConnectionFailed => e
        handle_faraday_error(e)
      end
    end
  end
end
