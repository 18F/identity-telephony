module Telephony
  class AlertSender
    SMS_MAX_LENGTH = 160

    def send_account_reset_notice(to:)
      message = I18n.t('telephony.account_reset_notice')
      response = adapter.send(message: message, to: to)
      log_response(response, context: __method__.to_s.gsub(/^send_/, ''))
      response
    end

    def send_account_reset_cancellation_notice(to:)
      message = I18n.t('telephony.account_reset_cancellation_notice')
      response = adapter.send(message: message, to: to)
      log_response(response, context: __method__.to_s.gsub(/^send_/, ''))
      response
    end

    def send_doc_auth_link(to:, link:)
      message = I18n.t('telephony.doc_auth_link', link: link)
      response = adapter.send(message: message, to: to)
      context = __method__.to_s.gsub(/^send_/, '')
      if link.length > SMS_MAX_LENGTH
        log_warning("link longer than #{SMS_MAX_LENGTH} characters", context: context)
      end
      log_response(response, context: context)
      response
    end

    def send_personal_key_regeneration_notice(to:)
      message = I18n.t('telephony.personal_key_regeneration_notice')
      response = adapter.send(message: message, to: to)
      log_response(response, context: __method__.to_s.gsub(/^send_/, ''))
      response
    end

    def send_personal_key_sign_in_notice(to:)
      message = I18n.t('telephony.personal_key_sign_in_notice')
      response = adapter.send(message: message, to: to)
      log_response(response, context: __method__.to_s.gsub(/^send_/, ''))
      response
    end

    def send_join_keyword_response(to:)
      message = I18n.t('telephony.join_keyword_response')
      response = adapter.send(message: message, to: to)
      log_response(response, context: __method__.to_s.gsub(/^send_/, ''))
      response
    end

    def send_stop_keyword_response(to:)
      message = I18n.t('telephony.stop_keyword_response')
      response = adapter.send(message: message, to: to)
      log_response(response, context: __method__.to_s.gsub(/^send_/, ''))
      response
    end

    def send_help_keyword_response(to:)
      message = I18n.t('telephony.help_keyword_response')
      response = adapter.send(message: message, to: to)
      log_response(response, context: __method__.to_s.gsub(/^send_/, ''))
      response
    end

    private

    def adapter
      case Telephony.config.adapter
      when :pinpoint
        Pinpoint::SmsSender.new
      when :test
        Test::SmsSender.new
      end
    end

    def log_response(response, context:)
      extra = {
        adapter: Telephony.config.adapter,
        channel: :sms,
        context: context,
      }
      output = response.to_h.merge(extra).to_json
      Telephony.config.logger.info(output)
    end

    def log_warning(alert, context:)
      Telephony.config.logger.warn({
        alert: alert,
        adapter: Telephony.config.adapter,
        channel: :sms,
        context: context,
      }.to_json)
    end
  end
end
