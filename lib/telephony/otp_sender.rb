module Telephony
  class OtpSender
    attr_reader :recipient_phone, :otp, :expiration, :channel, :domain

    def initialize(to:, otp:, expiration:, channel:, domain:)
      @recipient_phone = to
      @otp = otp
      @expiration = expiration
      @channel = channel.to_sym
      @domain = domain
    end

    def send_authentication_otp
      response = adapter.send(message: authentication_message, to: recipient_phone)
      log_response(response, context: :authentication)
      response
    end

    def send_confirmation_otp
      response = adapter.send(message: confirmation_message, to: recipient_phone)
      log_response(response, context: :confirmation)
      response
    end

    private

    # rubocop:disable all
    def adapter
      case [Telephony.config.adapter, channel.to_sym]
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

    def log_response(response, context:)
      extra = {
        adapter: Telephony.config.adapter,
        channel: channel,
        context: context,
      }
      output = response.to_h.merge(extra).to_json
      Telephony.config.logger.info(output)
    end

    def authentication_message
      I18n.t(
        "telephony.authentication_otp.#{channel}",
        code: otp_transformed_for_channel,
        expiration: expiration,
        domain: domain,
      )
    end

    def confirmation_message
      I18n.t(
        "telephony.confirmation_otp.#{channel}",
        code: otp_transformed_for_channel,
        expiration: expiration,
        domain: domain,
      )
    end

    def otp_transformed_for_channel
      return otp if channel != :voice

      otp.scan(/\d/).join(', ')
    end
  end
end
