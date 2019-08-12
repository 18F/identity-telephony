module Telephony
  class TelephonyError < StandardError
    def friendly_message
      I18n.t(friendly_error_message_key)
    end

    protected

    def friendly_error_message_key
      'telephony_error.friendly_message.generic'
    end
  end

  class ApiConnectionError < TelephonyError
    def friendly_error_message_key
      'telephony_error.friendly_message.api_connection'
    end
  end

  class InvalidPhoneNumberError < TelephonyError
    def friendly_error_message_key
      'telephony_error.friendly_message.invalid_phone_number'
    end
  end

  class InvalidCallingAreaError < TelephonyError
    def friendly_error_message_key
      'telephony_error.friendly_message.invalid_calling_area'
    end
  end

  class VoiceUnsupportedError < TelephonyError
    def friendly_error_message_key
      'telephony_error.friendly_message.voice_unsupported'
    end
  end

  class SmsUnsupportedError < TelephonyError
    def friendly_error_message_key
      'telephony_error.friendly_message.sms_unsupported'
    end
  end
end
