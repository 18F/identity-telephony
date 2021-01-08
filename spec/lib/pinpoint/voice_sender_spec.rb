describe Telephony::Pinpoint::VoiceSender do
  subject(:voice_sender) { described_class.new }

  describe '#send' do
    let(:pinpoint_response) do
      response = double()
      allow(response).to receive(:message_id).and_return('fake-message-id')
      response
    end
    let(:message) { 'This is a test!' }
    let(:sending_phone) { '+12223334444' }
    let(:recipient_phone) { '+1 (123) 456-7890' }
    let(:expected_message) do
      {
        content: {
          plain_text_message: {
            text: message,
            language_code: 'en-US',
            voice_id: 'Joey',
          },
        },
        destination_phone_number: recipient_phone,
        origination_phone_number: sending_phone,
      }
    end

    before do
      # More deterministic sending phone
      Telephony.config.pinpoint.voice_configs.first.longcode_pool = [sending_phone]
    end

    it 'initializes a pinpoint sms and voice client and uses that to send a message' do
      expect(voice_sender.client_configs.first.client).to receive(:send_voice_message).
        with(expected_message).
        and_return(pinpoint_response)

      response = voice_sender.send(message: message, to: recipient_phone)

      expect(response.success?).to eq(true)
      expect(response.extra[:message_id]).to eq('fake-message-id')
    end

    context 'when the current locale is spanish' do
      before do
        allow(I18n).to receive(:locale).and_return(:es)
      end

      it 'calls the user with a spanish voice' do
        expected_message[:content][:plain_text_message][:language_code] = 'es-US'
        expected_message[:content][:plain_text_message][:voice_id] = 'Miguel'
        expect(voice_sender.client_configs.first.client).to receive(:send_voice_message).
          with(expected_message).
          and_return(pinpoint_response)

        response = voice_sender.send(message: message, to: recipient_phone)

        expect(response.success?).to eq(true)
        expect(response.extra[:message_id]).to eq('fake-message-id')
      end
    end

    context 'when the current locale is french' do
      before do
        allow(I18n).to receive(:locale).and_return(:fr)
      end

      it 'calls the user with a french voice' do
        expected_message[:content][:plain_text_message][:language_code] = 'fr-FR'
        expected_message[:content][:plain_text_message][:voice_id] = 'Mathieu'
        expect(voice_sender.client_configs.first.client).to receive(:send_voice_message).
          with(expected_message).
          and_return(pinpoint_response)

        response = voice_sender.send(message: message, to: recipient_phone)

        expect(response.success?).to eq(true)
        expect(response.extra[:message_id]).to eq('fake-message-id')
      end
    end

    context 'when pinpoint responds with a limit exceeded response' do
      it 'returns a telephony error' do
        exception = Aws::PinpointSMSVoice::Errors::LimitExceededException.new(
          Seahorse::Client::RequestContext.new,
          'This is a test message',
        )
        expect(voice_sender.client_configs.first.client)
          .to receive(:send_voice_message).and_raise(exception)

        response = voice_sender.send(message: message, to: recipient_phone)

        error_message =
          'Aws::PinpointSMSVoice::Errors::LimitExceededException: This is a test message'

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::ThrottledError.new(error_message))
      end
    end

    context 'when pinpoint responds with an internal service error' do
      it 'returns a telephony error' do
        exception = Aws::PinpointSMSVoice::Errors::InternalServiceErrorException.new(
          Seahorse::Client::RequestContext.new,
          'This is a test message',
        )
        expect(voice_sender.client_configs.first.client)
          .to receive(:send_voice_message).and_raise(exception)

        response = voice_sender.send(message: message, to: recipient_phone)

        error_message =
          'Aws::PinpointSMSVoice::Errors::InternalServiceErrorException: This is a test message'

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::TelephonyError.new(error_message))
      end
    end

    context 'when pinpoint responds with a generic error' do
      it 'returns a telephony error' do
        exception = Aws::PinpointSMSVoice::Errors::BadRequestException.new(
          Seahorse::Client::RequestContext.new,
          'This is a test message',
        )
        expect(voice_sender.client_configs.first.client)
          .to receive(:send_voice_message).and_raise(exception)

        response = voice_sender.send(message: message, to: recipient_phone)

        error_message =
          'Aws::PinpointSMSVoice::Errors::BadRequestException: This is a test message'

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::TelephonyError.new(error_message))
      end
    end

    context 'when pinpoint raises a timeout exception' do
      it 'rescues the exception and returns an error' do
        exception = Seahorse::Client::NetworkingError.new(Net::ReadTimeout.new)
        expect(voice_sender.client_configs.first.client).
          to receive(:send_voice_message).and_raise(exception)

        response = voice_sender.send(message: message, to: recipient_phone)

        error_message = 'Seahorse::Client::NetworkingError: Net::ReadTimeout'

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::TelephonyError.new(error_message))
      end
    end

    context 'with multiple voice configs' do
      before do
        Telephony.config.pinpoint.add_voice_config do |voice|
          voice.region = 'backup-region'
          voice.access_key_id = 'fake-pinpoint-access-key-id-voice'
          voice.secret_access_key = 'fake-pinpoint-secret-access-key-voice'
          voice.longcode_pool = [backup_longcode]
        end
      end

      let(:backup_longcode) { '+18881112222' }

      context 'when the first config succeeds' do
        before do
          expect(voice_sender.client_configs.first.client).to receive(:send_voice_message).
            with(expected_message).
            and_return(pinpoint_response)

          expect(voice_sender.client_configs.last.client).to_not receive(:send_voice_message)
        end

        it 'only tries one client' do
          response = voice_sender.send(message: message, to: recipient_phone)
          expect(response.success?).to eq(true)
          expect(response.extra[:message_id]).to eq('fake-message-id')
        end
      end

      context 'when the first config errors' do
        before do
          # first config errors
          exception = Aws::PinpointSMSVoice::Errors::BadRequestException.new(
            Seahorse::Client::RequestContext.new,
            'This is a test message',
          )
          expect(voice_sender.client_configs.first.client)
            .to receive(:send_voice_message).and_raise(exception)

          # second config succeeds
          expected_message[:origination_phone_number] = backup_longcode
          expect(voice_sender.client_configs.last.client).to receive(:send_voice_message).
            with(expected_message).
            and_return(pinpoint_response)
        end

        it 'logs a warning and tries the other configs' do
          expect(Telephony.config.logger).to receive(:warn)

          response = voice_sender.send(message: message, to: recipient_phone)
          expect(response.success?).to eq(true)
          expect(response.extra[:message_id]).to eq('fake-message-id')
        end
      end
    end
  end
end
