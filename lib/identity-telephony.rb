require 'aws-sdk-pinpoint'
require 'aws-sdk-pinpointsmsvoice'
require 'forwardable'
require 'i18n'
require 'twilio-ruby'
require 'telephony/alert_sender'
require 'telephony/configuration'
require 'telephony/errors'
require 'telephony/otp_sender'
require 'telephony/test/call'
require 'telephony/test/message'
require 'telephony/test/sms_sender'
require 'telephony/test/voice_sender'
require 'telephony/pinpoint/sms_sender'
require 'telephony/pinpoint/longcode_sms_sender'
require 'telephony/pinpoint/voice_sender'
require 'telephony/twilio/programmable_sms_sender'
require 'telephony/twilio/programmable_voice_message'
require 'telephony/twilio/programmable_voice_message_encryptor'
require 'telephony/twilio/programmable_voice_sender'
require 'telephony/twilio/programmable_voice_twiml_builder'
require 'telephony/twilio/verify_client'

I18n.load_path += Dir[File.dirname(__FILE__) + '/../config/locales/*.yml']

module Telephony
  extend SingleForwardable

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

  def self.alert_sender
    AlertSender.new
  end

  def_delegators :alert_sender, :send_doc_auth_link,
                 :send_personal_key_regeneration_notice,
                 :send_personal_key_sign_in_notice, :send_join_keyword_response,
                 :send_stop_keyword_response, :send_help_keyword_response,
                 :send_account_reset_notice,
                 :send_account_reset_cancellation_notice
end
