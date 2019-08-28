module Telephony
  class AlertSender
    def send_account_reset_notice(to:, cancel_link:)
      message = I18n.t('telephony.account_reset_notice', cancel_link: cancel_link)
      adapter.send(message: message, to: to)
    end

    def send_account_reset_cancellation_notice(to:)
      message = I18n.t('telephony.account_reset_cancellation_notice')
      adapter.send(message: message, to: to)
    end

    def send_doc_auth_link(to:, link:)
      message = I18n.t('telephony.doc_auth_link', link: link)
      adapter.send(message: message, to: to)
    end

    def send_personal_key_regeneration_notice(to:)
      message = I18n.t('telephony.personal_key_regeneration_notice')
      adapter.send(message: message, to: to)
    end

    def send_personal_key_sign_in_notice(to:)
      message = I18n.t('telephony.personal_key_sign_in_notice')
      adapter.send(message: message, to: to)
    end

    def send_join_keyword_response(to:)
      message = I18n.t('telephony.join_keyword_response')
      adapter.send(message: message, to: to)
    end

    def send_stop_keyword_response(to:)
      message = I18n.t('telephony.stop_keyword_response')
      adapter.send(message: message, to: to)
    end

    def send_help_keyword_response(to:)
      message = I18n.t('telephony.help_keyword_response')
      adapter.send(message: message, to: to)
    end

    private

    def adapter
      case Telephony.config.adapter
      when :twilio
        Twilio::ProgrammableSmsSender.new
      when :pinpoint
        Pinpoint::SmsSender.new
      when :pinpoint_longcode
        Pinpoint::LongcodeSmsSender.new
      when :test
        Test::SmsSender.new
      end
    end
  end
end
