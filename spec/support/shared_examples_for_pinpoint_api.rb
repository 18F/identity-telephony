shared_examples 'a pinpoint api client' do
  describe 'error handling' do
    let(:status_code) { 400 }
    let(:delivery_status) { 'DUPLICATE' }
    let(:raised_error_message) { "Pinpoint Error: #{delivery_status} - #{status_code}" }

    before do
      Pinpoint::MockClient.reset!
      Pinpoint::MockClient.message_response_result_status_code = status_code
      Pinpoint::MockClient.message_response_result_delivery_status = delivery_status

      allow(Aws::Pinpoint::Client).to receive(:new).
        with(
          region: Telephony.config.pinpoint_region,
          access_key_id: Telephony.config.pinpoint_access_key_id,
          secret_access_key: Telephony.config.pinpoint_secret_access_key,
        ).
        and_return(Pinpoint::MockClient.new)
    end

    context 'when endpoint is a duplicate' do
      let(:delivery_status) { 'DUPLICATE' }

      it 'raises a duplicate endpoint error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::DuplicateEndpointError,
          raised_error_message,
        )
      end
    end

    context 'when the user opts out' do
      let(:delivery_status) { 'OPT_OUT' }

      it 'raises an opt out error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::OptOutError,
          raised_error_message,
        )
      end
    end

    context 'when a permanent failure occurs' do
      let(:delivery_status) { 'PERMANENT_FAILURE' }

      it 'raises an opt out error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::PermanentFailureError,
          raised_error_message,
        )
      end
    end

    context 'when a temporary failure occurs' do
      let(:delivery_status) { 'TEMPORARY_FAILURE' }

      it 'raises an opt out error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::TemporaryFailureError,
          raised_error_message,
        )
      end
    end

    context 'when the request is throttled' do
      let(:delivery_status) { 'THROTTLED' }

      it 'raises an opt out error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::ThrottledError,
          raised_error_message,
        )
      end
    end

    context 'when the request times out' do
      let(:delivery_status) { 'TIMEOUT' }

      it 'raises an opt out error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::TimeoutError,
          raised_error_message,
        )
      end
    end

    context 'when an unkown error occurs' do
      let(:delivery_status) { 'UNKNOWN_FAILURE' }

      it 'raises an opt out error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::UnknownFailureError,
          raised_error_message,
        )
      end
    end

    context 'when the API responds with an unrecognized error' do
      let(:delivery_status) { '' }

      it 'raises a generic telephony error' do
        expect { subject.send(message: 'hello!', to: '+11234567890') }.to raise_error(
          Telephony::TelephonyError,
          raised_error_message,
        )
      end
    end
  end
end
