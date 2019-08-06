module Telephony
  class TelephonyError < StandardError; end
  class ApiConnectionError < TelephonyError; end
  class InvalidPhoneNumberError < TelephonyError; end
  class InvalidCallingAreaError < TelephonyError; end
  class VoiceUnsupportedError < TelephonyError; end
  class SmsUnsupportedError < TelephonyError; end
end
