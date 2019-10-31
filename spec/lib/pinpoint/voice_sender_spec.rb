describe Telephony::Pinpoint::VoiceSender do
  describe '#send' do
    let(:pinpoint_sms_voice_client) { instance_double(Aws::PinpointSMSVoice::Client) }
    let(:message) { 'This is a test!' }
    let(:sending_phone) { '+12223334444' }
    let(:recipient_phone) { '+1 (123) 456-7890' }
    let(:expected_message) do
      {
        content: {
          plain_text_message: {
            text: message,
            language_code: 'en-US',
            voice_id: 'Joey'
          },
        },
        destination_phone_number: recipient_phone,
        origination_phone_number: sending_phone,
      }
    end

    before do
      credential_builder = instance_double(Telephony::Pinpoint::AwsCredentialBuilder)
      credentials = instance_double(Aws::Credentials)
      allow(Telephony::Pinpoint::AwsCredentialBuilder).to receive(:new).
        with(:voice).
        and_return(credential_builder)
      allow(credential_builder).to receive(:call).and_return(credentials)
      allow(Aws::PinpointSMSVoice::Client).to receive(:new).
        with(
          region: Telephony.config.pinpoint.voice.region,
          credentials: credentials,
          retry_limit: 1,
        ).
        and_return(pinpoint_sms_voice_client)
      allow(Telephony.config.pinpoint.voice.longcode_pool).to receive(:sample).and_return(sending_phone)
    end

    it 'initializes a pinpoint sms and voice client and uses that to send a message' do
      expect(pinpoint_sms_voice_client).to receive(:send_voice_message).with(expected_message)

      subject.send(message: message, to: recipient_phone)
    end

    context 'when the current locale is spanish' do
      before do
        allow(I18n).to receive(:locale).and_return(:es)
      end

      it 'calls the user with a spanish voice' do
        expected_message[:content][:plain_text_message][:language_code] = 'es-US'
        expected_message[:content][:plain_text_message][:voice_id] = 'Miguel'
        expect(pinpoint_sms_voice_client).to receive(:send_voice_message).with(expected_message)

        subject.send(message: message, to: recipient_phone)
      end
    end

    context 'when the current locale is french' do
      before do
        allow(I18n).to receive(:locale).and_return(:fr)
      end

      it 'calls the user with a french voice' do
        expected_message[:content][:plain_text_message][:language_code] = 'fr-FR'
        expected_message[:content][:plain_text_message][:voice_id] = 'Mathieu'
        expect(pinpoint_sms_voice_client).to receive(:send_voice_message).with(expected_message)

        subject.send(message: message, to: recipient_phone)
      end
    end

    context 'when pinpoint responds with a limitted exceeded response' do
      it 'raises a telephony error' do
        exception = Aws::PinpointSMSVoice::Errors::LimitExceededException.new(
          Seahorse::Client::RequestContext.new,
          'This is a test message',
        )
        expect(pinpoint_sms_voice_client).to receive(:send_voice_message).and_raise(exception)

        expect { subject.send(message: message, to: recipient_phone) }.to raise_error(
          Telephony::ThrottledError,
          'Aws::PinpointSMSVoice::Errors::LimitExceededException: This is a test message',
        )
      end
    end

    context 'when pinpoint responds with an internal service error' do
      it 'raises a telephony error' do
        exception = Aws::PinpointSMSVoice::Errors::InternalServiceErrorException.new(
          Seahorse::Client::RequestContext.new,
          'This is a test message',
        )
        expect(pinpoint_sms_voice_client).to receive(:send_voice_message).and_raise(exception)

        expect { subject.send(message: message, to: recipient_phone) }.to raise_error(
          Telephony::TelephonyError,
          'Aws::PinpointSMSVoice::Errors::InternalServiceErrorException: This is a test message',
        )
      end
    end

    context 'when pinpoint responds with a generic error' do
      it 'raises a telephony error' do
        exception = Aws::PinpointSMSVoice::Errors::BadRequestException.new(
          Seahorse::Client::RequestContext.new,
          'This is a test message',
        )
        expect(pinpoint_sms_voice_client).to receive(:send_voice_message).and_raise(exception)

        expect { subject.send(message: message, to: recipient_phone) }.to raise_error(
          Telephony::TelephonyError,
          'Aws::PinpointSMSVoice::Errors::BadRequestException: This is a test message',
        )
      end
    end
  end
end
