require 'i18n'
require 'twilio-ruby'
require 'telephony/configuration'
require 'telephony/errors'
require 'telephony/otp_sender'
require 'telephony/twilio/programmable_sms_sender'
require 'telephony/twilio/programmable_voice_message'
require 'telephony/twilio/programmable_voice_message_encryptor'
require 'telephony/twilio/programmable_voice_sender'
require 'telephony/twilio/programmable_voice_twiml_builder'
require 'telephony/twilio/verify_client'

I18n.load_path += Dir[File.dirname(__FILE__) + '/../config/locales/*.yml']

module Telephony
  def self.config
    @config ||= Configuration.new
    yield @config if block_given?
    @config
  end

  def self.send_authentication_otp(to:, otp:, expiration:, channel:)
    OtpSender.new(
      to: to,
      otp: otp,
      expiration: expiration,
      channel: channel
    ).send_authentication_otp
  end

  def self.send_confirmation_otp(to:, otp:, expiration:, channel:)
    OtpSender.new(
      to: to,
      otp: otp,
      expiration: expiration,
      channel: channel
    ).send_confirmation_otp
  end
end
