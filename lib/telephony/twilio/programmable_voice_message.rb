require 'uri'

module Telephony
  module Twilio
    class ProgrammableVoiceMessage
      class CallbackUrlError < StandardError; end

      attr_reader :message, :repeat_count, :locale

      def self.from_callback(callback_url)
        uri = URI.parse(callback_url)
        parsed_query = CGI.parse(uri.query || '')
        encrypted_message = (parsed_query['encrypted_message'])&.first
        if encrypted_message.nil?
          raise CallbackUrlError, 'The url is missing an encrypted message param'
        end
        from_encrypted_message(encrypted_message)
      rescue ProgrammableVoiceMessageEncryptor::EncryptionError => e
        raise CallbackUrlError, "Unable to decrypt the message. #{e.message}"
      end

      def initialize(message:, repeat_count: 5, locale: I18n.locale)
        @message = message
        @repeat_count = repeat_count
        @locale = locale
      end

      def callback_url
        uri = URI.parse(Telephony.config.twilio_voice_callback_base_url)
        uri.query = "encrypted_message=#{CGI.escape(to_encrypted_message)}"
        uri.to_s
      end

      def repeat_url
        return unless repeat_count > 0
        self.class.new(
          message: message,
          repeat_count: repeat_count - 1,
          locale: locale,
        ).callback_url
      end

      def twiml
        ProgrammableVoiceTwimlBuilder.new(self).call
      end

      def to_json(*args)
        {
          message: message,
          repeat_count: repeat_count,
          locale: locale,
        }.to_json(*args)
      end

      def to_encrypted_message
        ProgrammableVoiceMessageEncryptor.encrypt(self)
      end

      private

      def self.from_encrypted_message(encrypted_message)
        ProgrammableVoiceMessageEncryptor.decrypt(encrypted_message)
      end
    end
  end
end
