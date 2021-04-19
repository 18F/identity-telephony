describe Telephony::OtpSender do
  before do
    Telephony::Test::Message.clear_messages
    Telephony::Test::Call.clear_calls
  end

  context 'with the test adapter' do
    subject do
      described_class.new(
        to: to,
        otp: otp,
        expiration: expiration,
        channel: channel,
        domain: domain,
      )
    end

    let(:to) { '+1 (202) 262-1234' }
    let(:otp) { '123456' }
    let(:expiration) { 5 }
    let(:domain) { 'login.gov' }

    before do
      allow(Telephony.config).to receive(:adapter).and_return(:test)
    end

    context 'for SMS' do
      let(:channel) { :sms }

      it 'saves the OTP that was sent for authentication' do
        subject.send_authentication_otp

        expect(Telephony::Test::Message.last_otp).to eq(otp)
      end

      it 'saves the OTP that was sent for confirmation' do
        subject.send_confirmation_otp

        expect(Telephony::Test::Message.last_otp).to eq(otp)
      end
    end

    context 'for Voice' do
      let(:channel) { :voice }

      it 'saves the OTP that was sent for authentication' do
        subject.send_authentication_otp

        expect(Telephony::Test::Call.last_otp).to eq(otp)
      end

      it 'saves the OTP that was sent for confirmation' do
        subject.send_confirmation_otp

        expect(Telephony::Test::Call.last_otp).to eq(otp)
      end
    end
  end
end
