shared_examples 'a pinpoint sms client' do
  describe 'error handling' do
    let(:status_code) { 400 }
    let(:delivery_status) { 'DUPLICATE' }
    let(:raised_error_message) { "Pinpoint Error: #{delivery_status} - #{status_code}" }

    before do
      credential_builder = instance_double(Telephony::Pinpoint::AwsCredentialBuilder)
      credentials = instance_double(Aws::Credentials)
      allow(Telephony::Pinpoint::AwsCredentialBuilder).to receive(:new).
        with(:sms).
        and_return(credential_builder)
      allow(credential_builder).to receive(:call).and_return(credentials)
      allow(Aws::Pinpoint::Client).to receive(:new).
        with(
          region: Telephony.config.pinpoint.sms.region,
          credentials: credentials,
          retry_limit: 1,
        ).
        and_return(Pinpoint::MockClient.new)

      Pinpoint::MockClient.message_response_result_status_code = status_code
      Pinpoint::MockClient.message_response_result_delivery_status = delivery_status
    end

    context 'when endpoint is a duplicate' do
      let(:delivery_status) { 'DUPLICATE' }

      it 'raises a duplicate endpoint error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::DuplicateEndpointError.new(raised_error_message))
        expect(response.extra[:delivery_status]).to eq('DUPLICATE')
        expect(response.extra[:request_id]).to eq('fake-message-request-id')
      end
    end

    context 'when the user opts out' do
      let(:delivery_status) { 'OPT_OUT' }

      it 'raises an opt out error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::OptOutError.new(raised_error_message))
        expect(response.extra[:delivery_status]).to eq('OPT_OUT')
        expect(response.extra[:request_id]).to eq('fake-message-request-id')
      end
    end

    context 'when a permanent failure occurs' do
      let(:delivery_status) { 'PERMANENT_FAILURE' }

      it 'raises a permanent failure error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::PermanentFailureError.new(raised_error_message))
        expect(response.extra[:delivery_status]).to eq('PERMANENT_FAILURE')
        expect(response.extra[:request_id]).to eq('fake-message-request-id')
      end
    end

    context 'when a temporary failure occurs' do
      let(:delivery_status) { 'TEMPORARY_FAILURE' }

      it 'raises an opt out error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::TemporaryFailureError.new(raised_error_message))
        expect(response.extra[:delivery_status]).to eq('TEMPORARY_FAILURE')
        expect(response.extra[:request_id]).to eq('fake-message-request-id')
      end
    end

    context 'when the request is throttled' do
      let(:delivery_status) { 'THROTTLED' }

      it 'raises an opt out error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::ThrottledError.new(raised_error_message))
        expect(response.extra[:delivery_status]).to eq('THROTTLED')
        expect(response.extra[:request_id]).to eq('fake-message-request-id')
      end
    end

    context 'when the request times out' do
      let(:delivery_status) { 'TIMEOUT' }

      it 'raises an opt out error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::TimeoutError.new(raised_error_message))
        expect(response.extra[:delivery_status]).to eq('TIMEOUT')
        expect(response.extra[:request_id]).to eq('fake-message-request-id')
      end
    end

    context 'when an unkown error occurs' do
      let(:delivery_status) { 'UNKNOWN_FAILURE' }

      it 'raises an opt out error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::UnknownFailureError.new(raised_error_message))
        expect(response.extra[:delivery_status]).to eq('UNKNOWN_FAILURE')
        expect(response.extra[:request_id]).to eq('fake-message-request-id')
      end
    end

    context 'when the API responds with an unrecognized error' do
      let(:delivery_status) { '' }

      it 'raises a generic telephony error' do
        response = subject.send(message: 'hello!', to: '+11234567890')

        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::TelephonyError.new(raised_error_message))
        expect(response.extra[:delivery_status]).to eq('')
        expect(response.extra[:request_id]).to eq('fake-message-request-id')
      end
    end
  end
end
