describe Telephony::Twilio::VerifyClient do
  describe '#send' do
    it 'sends a request to the verify API with the code' do
      request = stub_request(
        :post,
        'https://api.authy.com/protected/json/phones/verification/start',
      ).with(
        body: {
          code_length: '6',
          country_code: '81',
          custom_code: '123456',
          locale: 'en',
          phone_number: '543543643',
          via: 'sms',
        },
        headers: {
          'X-Authy-API-Key' => 'fake-twilio-verify-api-key',
        }
      ).to_return(status: 200, body: '', headers: {})

      subject.send(otp: '123456', to: '+81543543643')

      expect(request).to have_been_made
    end

    it 'raises an error if the request times out' do
      faraday = double(Faraday)
      allow(Faraday).to receive(:new).twice.and_return(faraday)

      expect(faraday).to receive(:post).and_raise(Faraday::TimeoutError)
      expect do
        described_class.new.send(otp: '123456', to: '+81543543643')
      end.to raise_error(Telephony::ApiConnectionError, 'Verify API Error - Faraday::TimeoutError')

      expect(faraday).to receive(:post).and_raise(Faraday::ConnectionFailed.new('error'))
      expect do
        described_class.new.send(otp: '123456', to: '+81543543643')
      end.to raise_error(
        Telephony::ApiConnectionError,
        'Verify API Error - Faraday::ConnectionFailed',
      )
    end

    describe 'error handling' do
      let(:error_code) { 60_033 }
      let(:error_message) { 'The thing did a thing' }
      let(:raised_error_message) { "Twilio Verify Error: #{error_code} - #{error_message}" }

      before do
        stub_request(
          :post,
          'https://api.authy.com/protected/json/phones/verification/start',
        ).to_return(
          status: 400,
          body: { error_code: error_code, message: error_message }.to_json,
        )
      end

      context 'when the API responds with an invalid phone number error' do
        let(:error_code) { 60_033 }

        it 'raises an invalid phone error' do
          expect { subject.send(otp: '123456', to: '+81543543643') }.to raise_error(
            Telephony::InvalidPhoneNumberError,
            raised_error_message,
          )
        end
      end

      context 'when the API responds with an invalid calling area' do
        let(:error_code) { 60_078 }

        it 'raises an invalid phone error' do
          expect { subject.send(otp: '123456', to: '+81543543643') }.to raise_error(
            Telephony::InvalidPhoneNumberError,
            raised_error_message,
          )
        end
      end

      context 'when the API responds that the phone does not support SMS' do
        let(:error_code) { 60_082 }

        it 'raises an invalid phone error' do
          expect { subject.send(otp: '123456', to: '+81543543643') }.to raise_error(
            Telephony::SmsUnsupportedError,
            raised_error_message,
          )
        end
      end

      context 'when the API responds that the phone does not support voice calls' do
        let(:error_code) { 60_083 }

        it 'raises an invalid phone error' do
          expect { subject.send(otp: '123456', to: '+81543543643') }.to raise_error(
            Telephony::VoiceUnsupportedError,
            raised_error_message,
          )
        end
      end
    end
  end
end
