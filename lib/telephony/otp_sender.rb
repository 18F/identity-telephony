module Telephony
  class OtpSender
    attr_reader :recipient_phone, :otp, :expiration, :channel

    def initialize(to:, otp:, expiration:, channel:)
      @recipient_phone = to
      @otp = otp
      @expiration = expiration
      @channel = channel.to_sym
    end

    def send_authentication_otp
      adapter.send(message: authentication_message, to: recipient_phone)
    end

    def send_confirmation_otp
      adapter.send(message: confirmation_message, to: recipient_phone)
    end

    private

    # rubocop:disable all
    def adapter
      case [Telephony.config.adapter, channel.to_sym]
      when [:twilio, :sms]
        Twilio::ProgrammableSmsSender.new
      when [:twilio, :voice]
        Twilio::ProgrammableVoiceSender.new
      when [:pinpoint, :sms]
        Pinpoint::SmsSender.new
      when [:pinpoint, :voice]
        Pinpoint::VoiceSender.new
      when [:test, :sms]
        Test::SmsSender.new
      when [:test, :voice]
        Test::VoiceSender.new
      else
        raise "Unknown telephony adapter #{Telephony.config.adapter} for channel #{channel.to_sym}"
      end
    end
    # rubocop:enable all

    def authentication_message
      I18n.t(
        "telephony.authentication_otp.#{channel}",
        code: otp_transformed_for_channel,
        expiration: expiration,
      )
    end

    def confirmation_message
      I18n.t(
        "telephony.confirmation_otp.#{channel}",
        code: otp_transformed_for_channel,
        expiration: expiration,
      )
    end

    def otp_transformed_for_channel
      return otp if channel != :voice

      otp.scan(/\d/).join(', ')
    end
  end
end
