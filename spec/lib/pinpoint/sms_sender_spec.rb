describe Telephony::Pinpoint::SmsSender do
  subject(:sms_sender) { described_class.new }
  let(:sms_config) { Telephony.config.pinpoint.sms_configs.first }
  let(:mock_client) { Pinpoint::MockClient.new(sms_config) }

  # Monkeypatch library class so we can use it for argument matching
  class Aws::Credentials
    def ==(other)
      self.access_key_id == other.access_key_id &&
        self.secret_access_key == other.secret_access_key
    end
  end

  before do
    expect(sms_sender).to receive(:build_client)
      .with(
        region: sms_config.region,
        credentials: Aws::Credentials.new(sms_config.access_key_id, sms_config.secret_access_key),
        retry_limit: 0,
      ).and_return(mock_client)
  end

  describe 'error handling' do
    let(:status_code) { 400 }
    let(:delivery_status) { 'DUPLICATE' }
    let(:raised_error_message) { "Pinpoint Error: #{delivery_status} - #{status_code}" }

    before do
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

    context 'when a timeout exception is raised' do
      let(:raised_error_message) { 'Seahorse::Client::NetworkingError: Net::ReadTimeout' }

      it 'handles the exception' do
        expect(mock_client).to receive(:send_messages).and_raise(Seahorse::Client::NetworkingError.new(Net::ReadTimeout.new))
        response = subject.send(message: 'hello!', to: '+11234567890')
        expect(response.success?).to eq(false)
        expect(response.error).to eq(Telephony::TelephonyError.new(raised_error_message))
        expect(response.extra[:delivery_status]).to eq nil
        expect(response.extra[:request_id]).to eq nil
      end
    end
  end

  describe '#send' do
    it 'initializes a pinpoint client and uses that to send a message with a shortcode' do
      response = subject.send(message: 'This is a test!', to: '+1 (123) 456-7890')

      expected_result = {
        application_id: Telephony.config.pinpoint.sms_configs.first.application_id,
        message_request: {
          addresses: {
            '+1 (123) 456-7890' => { channel_type: 'SMS' },
          },
          message_configuration: {
            sms_message: {
              body: 'This is a test!',
              message_type: 'TRANSACTIONAL',
              origination_number: '123456',
            },
          },
        },
      }

      expect(Pinpoint::MockClient.last_request).to eq(expected_result)
      expect(response.success?).to eq(true)
      expect(response.error).to eq(nil)
      expect(response.extra[:request_id]).to eq('fake-message-request-id')
    end

    context 'with multiple sms configs' do
      let(:backup_sms_config) { Telephony.config.pinpoint.sms_configs.last }
      let(:backup_mock_client) { Pinpoint::MockClient.new(backup_sms_config) }

      before do
        Telephony.config.pinpoint.add_sms_config do |sms|
          sms.region = 'backup-sms-region'
          sms.access_key_id = 'fake-pnpoint-access-key-id-sms'
          sms.secret_access_key = 'fake-pinpoint-secret-access-key-sms'
          sms.application_id = 'backup-sms-application-id'
        end

        expect(sms_sender).to receive(:build_client)
          .with(
            region: backup_sms_config.region,
            credentials: Aws::Credentials.new(backup_sms_config.access_key_id, backup_sms_config.secret_access_key),
            retry_limit: 0,
          ).and_return(backup_mock_client)
      end

      context 'when the first config succeeds' do
        it 'only tries one client' do
          expect(sms_sender.client_configs.last.client).to_not receive(:send_messages)

          response = subject.send(message: 'This is a test!', to: '+1 (123) 456-7890')
          expect(response.success?).to eq(true)
        end
      end

      context 'when the first config errors' do
        before do
          Pinpoint::MockClient.message_response_result_status_code = 400
          Pinpoint::MockClient.message_response_result_delivery_status = 'DUPLICATE'
        end

        it 'logs a warning for each failure and tries the other configs' do
          expect(Telephony.config.logger).to receive(:warn).exactly(2).times

          response = subject.send(message: 'This is a test!', to: '+1 (123) 456-7890')

          expect(response.success?).to eq(false)
        end
      end

      context 'when the first config raises a timeout exception' do
        let(:raised_error_message) { 'Seahorse::Client::NetworkingError: Net::ReadTimeout' }

        it 'logs a warning for each failure and tries the other configs' do
          expect(sms_sender.client_configs.first.client).to receive(:send_messages).and_raise(Seahorse::Client::NetworkingError.new(Net::ReadTimeout.new)).once
          expect(sms_sender.client_configs.last.client).to receive(:send_messages).and_raise(Seahorse::Client::NetworkingError.new(Net::ReadTimeout.new)).once

          response = subject.send(message: 'This is a test!', to: '+1 (123) 456-7890')
          expect(response.success?).to eq(false)
          expect(response.error).to eq(Telephony::TelephonyError.new(raised_error_message))
        end
      end
    end
  end
end
