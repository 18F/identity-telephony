require 'base64'
require 'openssl'

module Telephony
  module Twilio
    class ProgrammableVoiceMessageEncryptor
      class EncryptionError < StandardError; end

      Ciphertext = Struct.new(:encrypted_data, :iv, :tag) do
        def to_json(*args)
          {
            data: encode(encrypted_data),
            iv: encode(iv),
            tag: encode(tag),
          }.to_json(args)
        end

        def encode(bytes)
          Base64.strict_encode64(bytes)
        end

        def self.from_json(json)
          parsed_json = JSON.parse(json, symbolize_names: true)

          if !parsed_json.is_a?(Hash)
            raise EncryptionError, 'The ciphertext is not a valid JSON object'
          end

          new(decode(parsed_json[:data]), decode(parsed_json[:iv]), decode(parsed_json[:tag]))
        rescue JSON::ParserError, TypeError
          raise EncryptionError, 'Failed to parse ciphertext JSON'
        end

        def self.decode(base64)
          if base64.nil?
            raise EncryptionError, 'Unable to base64 decode nil'
          end
          Base64.strict_decode64(base64)
        rescue ArgumentError
          raise EncryptionError, 'The ciphertext contains invalid base64'
        end
      end

      AUTH_DATA = 'Twilio Programmable Voice Message'

      def self.encrypt(message)
        cipher = OpenSSL::Cipher::AES.new(256, :gcm)
        cipher.encrypt
        cipher.key = encryption_key
        iv = cipher.random_iv
        cipher.auth_data = AUTH_DATA
        encrypted_data = cipher.update(message.to_json) + cipher.final
        tag = cipher.auth_tag
        Ciphertext.new(encrypted_data, iv, tag).to_json
      end

      def self.decrypt(encrypted_message)
        ciphertext = Ciphertext.from_json(encrypted_message)
        cipher = OpenSSL::Cipher::AES.new(256, :gcm)
        cipher.decrypt
        cipher.key = encryption_key
        cipher.iv = ciphertext.iv
        cipher.auth_data = AUTH_DATA
        cipher.auth_tag = ciphertext.tag
        decrypted_json = cipher.update(ciphertext.encrypted_data) + cipher.final

        parsed_decrypted_json = JSON.parse(decrypted_json, symbolize_names: true)
        ProgrammableVoiceMessage.new(parsed_decrypted_json)
      rescue OpenSSL::OpenSSLError, ArgumentError
        raise EncryptionError, 'An OpenSSL error occured'
      end

      def self.encryption_key
        Base64.decode64(Telephony.config.twilio_voice_callback_encryption_key)
      end
    end
  end
end
