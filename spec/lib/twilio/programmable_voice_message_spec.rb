describe Telephony::Twilio::ProgrammableVoiceMessage do
  subject { described_class.new(message: 'This is a test!') }

  describe '.from_callback' do
    it 'returns an object parsed from the encrypted_message param on the url' do
      encrypted_message = Telephony::Twilio::ProgrammableVoiceMessageEncryptor.encrypt(subject)
      callback_url = 'https://example.com/asdf?encrypted_message=' + CGI.escape(encrypted_message)

      result = described_class.from_callback(callback_url)

      expect(result.message).to eq('This is a test!')
      expect(result.locale).to eq('en')
      expect(result.repeat_count).to eq(5)
    end

    it 'raises an error if the encrypted_message param is missing' do
      callback_url = 'https://example.com/'

      expect { described_class.from_callback(callback_url) }.to raise_error(
        Telephony::Twilio::ProgrammableVoiceMessage::CallbackUrlError,
        'The url is missing an encrypted message param',
      )
    end

    it 'raises an error if the encrypted_message param cannot be decrypted' do
      encrypted_message = '{ "iv": "asdf", "tag": "asdf", "data": "asdf" }'
      callback_url = 'https://example.com/asdf?encrypted_message=' + CGI.escape(encrypted_message)

      expect { described_class.from_callback(callback_url) }.to raise_error(
        Telephony::Twilio::ProgrammableVoiceMessage::CallbackUrlError,
        'Unable to decrypt the message. An OpenSSL error occured',
      )
    end
  end

  describe '#callback_url' do
    it 'returns a url with the correct base url and a message that can be parsed from the params' do
      callback_url = subject.callback_url

      expect(callback_url).to match(/^#{Telephony.config.twilio.voice_callback_base_url}/)

      parsed_message = described_class.from_callback(callback_url)

      expect(parsed_message.message).to eq('This is a test!')
      expect(parsed_message.locale).to eq('en')
      expect(parsed_message.repeat_count).to eq(5)
    end
  end

  describe '#repeat_url' do
    context 'when the repeat count is greater than 0' do
      it 'returns a callback url for the message with the repeat count decremented by 1' do
        message = described_class.new(message: 'This is a test!', repeat_count: 4)

        repeat_url = message.repeat_url

        repeat_message = described_class.from_callback(repeat_url)
        expect(repeat_message.message).to eq('This is a test!')
        expect(repeat_message.repeat_count).to eq(3)
      end
    end

    context 'when the repeat count is 0' do
      it 'returns nil' do
        message = described_class.new(message: 'This is a test!', repeat_count: 0)

        repeat_url = message.repeat_url

        expect(repeat_url).to eq(nil)
      end
    end
  end
end
