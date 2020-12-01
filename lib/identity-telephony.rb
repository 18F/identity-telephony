require 'aws-sdk-pinpoint'
require 'aws-sdk-pinpointsmsvoice'
require 'forwardable'
require 'i18n'
require 'telephony/util'
require 'telephony/alert_sender'
require 'telephony/configuration'
require 'telephony/errors'
require 'telephony/otp_sender'
require 'telephony/response'
require 'telephony/test/call'
require 'telephony/test/message'
require 'telephony/test/error_simulator'
require 'telephony/test/sms_sender'
require 'telephony/test/voice_sender'
require 'telephony/pinpoint/aws_credential_builder'
require 'telephony/pinpoint/sms_sender'
require 'telephony/pinpoint/voice_sender'

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
