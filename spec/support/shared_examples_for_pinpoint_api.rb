shared_examples 'a pinpoint api client' do
  describe 'error handling' do
    let(:error_code) { 'DUPLICATE' }
    let(:error_message) { '400' }
    let(:raised_error_message) { "Pinpoint Error: #{error_code} - #{error_message}" }
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
      client = instance_double(Aws::Pinpoint::Client)
      service = double
      allow(Aws::Pinpoint::Client).to receive(:new).and_return(client)
      response = instance_double(Seahorse::Client::Response)
      allow(client).to receive(:send_messages).and_return(response)
    end

    context 'when endpoint is a duplicate' do
      let(:error_code) { 'DUPLICATE' }

      it 'raises a duplicate endpoint error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::DuplicateEndpointError,
          raised_error_message,
        )
      end
    end

    context 'when the user opts out' do
      let(:error_code) { 'OPT_OUT' }

      it 'raises an opt out error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::OptOutError,
          raised_error_message,
        )
      end
    end

    context 'when the user opts out' do
      let(:error_code) { 'PERMANENT_FAILURE' }

      it 'raises an opt out error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::PermanentFailureError,
          raised_error_message,
        )
      end
    end

    context 'when the user opts out' do
      let(:error_code) { 'TEMPORARY_FAILURE' }

      it 'raises an opt out error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::TemporaryFailureError,
          raised_error_message,
        )
      end
    end

    context 'when the user opts out' do
      let(:error_code) { 'THROTTLED' }

      it 'raises an opt out error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::ThrottledError,
          raised_error_message,
        )
      end
    end

    context 'when the user opts out' do
      let(:error_code) { 'UNKNOWN_FAILURE' }

      it 'raises an opt out error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::TimeoutError,
          raised_error_message,
        )
      end
    end

    context 'when the API responds with an unrecognized error' do
      let(:error_code) { '' }

      it 'raises a generic telephony error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::TelephonyError,
          raised_error_message,
        )
      end
    end
  end
end
