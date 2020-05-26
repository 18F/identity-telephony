require 'logger'

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

  class PinpointConfiguration
    attr_reader :sms_configs, :voice_configs

    def initialize
      @sms_configs = []
      @voice_configs = []
    end

    # Adds a new SMS configuration
    # @yieldparam [PinpointSmsConfiguration] sms an sms configuration object configure
    def add_sms_config
      raise 'missing sms configuration block' unless block_given?
      sms = PinpointSmsConfiguration.new(region: 'us-west-2')
      yield sms
      sms_configs << sms
      sms
    end

    # Adds a new voice configuration
    # @yieldparam [PinpointVoiceConfiguration] voice a voice configuration object configure
    def add_voice_config
      raise 'missing voice configuration block' unless block_given?
      voice = PinpointVoiceConfiguration.new(region: 'us-west-2')
      yield voice
      voice_configs << voice
      voice
    end
  end

  PINPOINT_CONFIGURATION_NAMES = [
    :region, :access_key_id, :secret_access_key,
    :credential_role_arn, :credential_role_session_name, :credential_external_id
  ].freeze
  PinpointVoiceConfiguration = Struct.new(:longcode_pool, *PINPOINT_CONFIGURATION_NAMES, keyword_init: true)
  PinpointSmsConfiguration = Struct.new(
    :application_id,
    :shortcode,
    *PINPOINT_CONFIGURATION_NAMES,
    keyword_init: true,
  )

  class Configuration
    attr_writer :adapter
    attr_reader :twilio, :pinpoint
    attr_accessor :logger

    # rubocop:disable Metrics/MethodLength
    def initialize
      @adapter = :pinpoint
      @logger = Logger.new(STDOUT)
      @twilio = TwilioConfiguration.new(
        timeout: 5,
        record_voice: false,
      )
      @pinpoint = PinpointConfiguration.new
    end
    # rubocop:enable Metrics/MethodLength

    def adapter
      @adapter.to_sym
    end
  end
end
