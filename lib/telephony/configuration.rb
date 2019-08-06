module Telephony
  class Configuration
    attr_accessor :adpater,
                  :twilio_timeout,
                  :twilio_numbers,
                  :twilio_sid,
                  :twilio_auth_token,
                  :twilio_messaging_service_sid,
                  :twilio_record_voice,
                  :twilio_verify_api_key,
                  :twilio_voice_callback_encryption_key,
                  :twilio_voice_callback_base_url

    def initialize
      self.adapter ||= :twilio
      self.twilio_timeout ||= 5
      self.twilio_record_voice ||= false
    end

    def adpater
      @adapter.to_sym
    end
  end
end
