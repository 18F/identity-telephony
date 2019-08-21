module Telephony
  class Configuration
    attr_writer   :adapter
    attr_accessor :twilio_timeout,
                  :twilio_numbers,
                  :twilio_sid,
                  :twilio_auth_token,
                  :twilio_messaging_service_sid,
                  :twilio_record_voice,
                  :twilio_verify_api_key,
                  :twilio_voice_callback_encryption_key,
                  :twilio_voice_callback_base_url,
                  :pinpoint_region,
                  :pinpoint_access_key_id,
                  :pinpoint_secret_access_key,
                  :pinpoint_application_id

    def initialize
      @adapter = :twilio
      self.twilio_timeout = 5
      self.twilio_record_voice = false
    end

    def adapter
      @adapter.to_sym
    end
  end
end
