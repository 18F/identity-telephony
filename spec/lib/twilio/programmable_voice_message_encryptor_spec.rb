describe Telephony::Twilio::ProgrammableVoiceMessageEncryptor do
  describe '.encrypt' do
    it 'should be able to encrypt a programmable voice message' do
      message = Telephony::Twilio::ProgrammableVoiceMessage.new(message: 'This is a test!')
      encrypted_message = described_class.encrypt(message)

      expect(encrypted_message).to be_a_kind_of(String)
      expect(encrypted_message).to_not match(/(This|test\!)/)

      decrypted_object = described_class.decrypt(encrypted_message)

      expect(decrypted_object).to be_a_kind_of(Telephony::Twilio::ProgrammableVoiceMessage)
      expect(decrypted_object.message).to eq(message.message)
    end
  end

  describe '.decrpyt' do
    it 'should be able to decrypt a programmable voice message' do
      message = Telephony::Twilio::ProgrammableVoiceMessage.new(message: 'This is a test!')
      encrypted_message = described_class.encrypt(message)
      decrypted_object = described_class.decrypt(encrypted_message)
      expect(decrypted_object.message).to eq(message.message)
    end

    it 'should raise an encryption error for invalid JSON' do
      expect { described_class.decrypt('this is "" invalid JSON') }.to raise_error(
        Telephony::Twilio::ProgrammableVoiceMessageEncryptor::EncryptionError,
        'Failed to parse ciphertext JSON',
      )

      expect { described_class.decrypt('123') }.to raise_error(
        Telephony::Twilio::ProgrammableVoiceMessageEncryptor::EncryptionError,
        'The ciphertext is not a valid JSON object',
      )

      expect { described_class.decrypt('') }.to raise_error(
        Telephony::Twilio::ProgrammableVoiceMessageEncryptor::EncryptionError,
        'Failed to parse ciphertext JSON',
      )

      expect { described_class.decrypt(nil) }.to raise_error(
        Telephony::Twilio::ProgrammableVoiceMessageEncryptor::EncryptionError,
        'Failed to parse ciphertext JSON',
      )
    end

    it 'should raise an encryption error for invalid Base64' do
      invalid_base64 = '{ "iv": "123abc", "tag": "123abc", "data": "invalid!!!" }'

      expect { described_class.decrypt(invalid_base64) }.to raise_error(
        Telephony::Twilio::ProgrammableVoiceMessageEncryptor::EncryptionError,
        'The ciphertext contains invalid base64',
      )
    end

    it 'should raise an encription error if a component is missing from the ciphertext' do
      missing_component = '{ "iv": "123abc", "tag": "123abc" }'

      expect { described_class.decrypt(missing_component) }.to raise_error(
        Telephony::Twilio::ProgrammableVoiceMessageEncryptor::EncryptionError,
        'Unable to base64 decode nil',
      )
    end

    it 'should raise an encryption error if decrpytion fails' do
      message = Telephony::Twilio::ProgrammableVoiceMessage.new(message: 'This is a test!')
      encrypted_message = described_class.encrypt(message)
      parsed_message = JSON.parse(encrypted_message)
      corrupted_message = {
        data: Base64.strict_encode64('fake ciphertext'),
        iv: parsed_message['iv'],
        tag: parsed_message['tag'],
      }.to_json

      expect { described_class.decrypt(corrupted_message) }.to raise_error(
        Telephony::Twilio::ProgrammableVoiceMessageEncryptor::EncryptionError,
        'An OpenSSL error occured',
      )
    end
  end
end
