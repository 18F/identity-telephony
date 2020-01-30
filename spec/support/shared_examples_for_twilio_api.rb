shared_examples 'a twilio api client' do
  describe 'error handling' do
    let(:error_code) { 21_211 }
    let(:error_message) { 'The thing did a thing' }
    let(:raised_error_message) { "Twilio REST API Error: #{error_code} - #{error_message}" }
    let(:error) do
      response = double
      allow(response).to receive(:status_code).and_return(400)
      allow(response).to receive(:body).and_return(code: 123)
      rest_error = Twilio::REST::RestError.new('', response)
      allow(rest_error).to receive(:code).and_return(error_code)
      allow(rest_error).to receive(:message).and_return(error_message)
      rest_error
    end

    before do
      client = instance_double(::Twilio::REST::Client)
      service = double
      allow(::Twilio::REST::Client).to receive(:new).and_return(client)
      allow(service).to receive(:create).and_raise(error)
      allow(client).to receive(:messages).and_return(service)
      allow(client).to receive(:calls).and_return(service)
    end

    context 'when the phone number is invalid' do
      it 'raises an invalid phone number error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::InvalidPhoneNumberError.new(raised_error_message))
      end
    end

    context 'when the phone number does not support SMS' do
      let(:error_code) { 21_614 }

      it 'raises a SMS unsupported error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::SmsUnsupportedError.new(raised_error_message))
      end
    end

    context 'when the phone number does not support voice' do
      let(:error_code) { 13_224 }

      it 'raises a voice unsupported error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::VoiceUnsupportedError.new(raised_error_message))
      end
    end

    context 'when the calling area is not enabled or supported' do
      let(:error_code) { 21_215 }

      it 'raises a invalid calling area error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::InvalidCallingAreaError.new(raised_error_message))
      end
    end

    context 'when the request times out' do
      let(:error_code) { 4_815_162_342 }

      it 'raises a API connection error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::ApiConnectionError.new(raised_error_message))
      end
    end

    context 'when the API responds with an unrecognized error' do
      let(:error_code) { 123 }

      it 'raises a generic telephony error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::TelephonyError.new(raised_error_message))
      end
    end

    context 'when Faraday times out' do
      let(:error) { Faraday::TimeoutError.new('test error') }
      let(:raised_error_message) { 'Faraday error: Faraday::TimeoutError - test error' }

      it 'raises a API connection error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::ApiConnectionError.new(raised_error_message))
      end
    end

    context 'when Faraday fails to make a connection' do
      let(:error) { Faraday::ConnectionFailed.new('test error') }
      let(:raised_error_message) { 'Faraday error: Faraday::ConnectionFailed - test error' }

      it 'raises a API connection error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::ApiConnectionError.new(raised_error_message))
      end
    end
  end
end
