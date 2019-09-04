module Telephony
  TwilioConfiguration = Struct.new(
    :timeout,
    :numbers,
    :sid,
    :auth_token,
    :messaging_service_sid,
    :record_voice,
    :verify_api_key,
    :voice_callback_encryption_key,
    :voice_callback_base_url,
    keyword_init: true,
  )

  PinpointConfiguration = Struct.new(
    :sms,
    :voice,
    keyword_init: true,
  )
  PINPOINT_CONFIGURATION_NAMES = [
    :region, :access_key_id, :secret_access_key, :application_id, :longcode_pool
  ].freeze
  PinpointVoiceConfiguration = Struct.new(*PINPOINT_CONFIGURATION_NAMES)
  PinpointSmsConfiguration = Struct.new(:shortcode, *PINPOINT_CONFIGURATION_NAMES)

  class Configuration
    attr_writer :adapter
    attr_reader :twilio, :pinpoint

    def initialize
      @adapter = :twilio
      @twilio = TwilioConfiguration.new(timeout: 5, record_voice: false)
      pinpoint_voice = PinpointVoiceConfiguration.new(
        region: 'us-west-2',
      )
      pinpoint_sms = PinpointSmsConfiguration.new(
        region: 'us-west-2',
      )
      @pinpoint = PinpointConfiguration.new(voice: pinpoint_voice, sms: pinpoint_sms)
    end

    def adapter
      @adapter.to_sym
    end
  end
end
