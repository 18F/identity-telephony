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
      if should_use_twilio_verify?
        return Twilio::VerifyClient.new.send(otp: otp, to: recipient_phone)
      end
      adapter.send(message: authentication_message, to: recipient_phone)
    end

    def send_confirmation_otp
      if should_use_twilio_verify?
        return Twilio::VerifyClient.new.send(otp: otp, to: recipient_phone)
      end
      adapter.send(message: confirmation_message, to: recipient_phone)
    end

    private

    def should_use_twilio_verify?
      return false unless Telephony.config.adapter == :twilio
      return false unless channel == :sms
      destination_country = Phonelib.parse(recipient_phone).country
      !%w[US CA MX].include?(destination_country)
    end

    def adapter
      if channel == :sms
        Twilio::ProgrammableSmsSender.new
      else
        Twilio::ProgrammableVoiceSender.new
      end
    end

    def authentication_message
      I18n.t(
        "authentication_otp.#{channel}",
        code: otp_transformed_for_channel,
        expiration: expiration,
      )
    end

    def confirmation_message
      I18n.t(
        "confirmation_otp.#{channel}",
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
