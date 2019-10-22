describe Telephony::OtpSender do
  context 'with the twilio adapter' do
    subject { described_class.new(to: to, otp: otp, expiration: expiration, channel: channel) }

    let(:to) { '+1 (202) 262-1234' }
    let(:otp) { '123456' }
    let(:expiration) { 5 }

    before do
      allow(Telephony.config).to receive(:adapter).and_return(:twilio)
    end

    context 'for domestic SMS' do
      let(:channel) { :sms }

      it 'sends an authentication OTP with Twilio Programmable SMS' do
        message = 'Enter 123456 in login.gov to continue signing. This security code will expire in 5 minutes.'

        adapter = instance_double(Telephony::Twilio::ProgrammableSmsSender)
        expect(adapter).to receive(:send).with(message: message, to: to)
        expect(Telephony::Twilio::ProgrammableSmsSender).to receive(:new).and_return(adapter)

        subject.send_authentication_otp
      end

      it 'sends a confirmation OTP with Twilio Programmable SMS' do
        message = 'Enter 123456 in login.gov to confirm your phone number. This security code will expire in 5 minutes.'

        adapter = instance_double(Telephony::Twilio::ProgrammableSmsSender)
        expect(adapter).to receive(:send).with(message: message, to: to)
        expect(Telephony::Twilio::ProgrammableSmsSender).to receive(:new).and_return(adapter)

        subject.send_confirmation_otp
      end
    end

    context 'for domestic voice' do
      let(:channel) { :voice }

      it 'sends an authentication OTP with Twilio Programmable Voice' do
        message = 'Hello! Your login.gov one time passcode is, 1, 2, 3, 4, 5, 6, again, your passcode is, 1, 2, 3, 4, 5, 6. This code expires in 5 minutes.'

        adapter = instance_double(Telephony::Twilio::ProgrammableVoiceSender)
        expect(adapter).to receive(:send).with(message: message, to: to)
        expect(Telephony::Twilio::ProgrammableVoiceSender).to receive(:new).and_return(adapter)

        subject.send_confirmation_otp
      end

      it 'sends a confirmation OTP with Twilio Programmable Voice' do
        message = 'Hello! Your login.gov one time passcode is, 1, 2, 3, 4, 5, 6, again, your passcode is, 1, 2, 3, 4, 5, 6. This code expires in 5 minutes.'

        adapter = instance_double(Telephony::Twilio::ProgrammableVoiceSender)
        expect(adapter).to receive(:send).with(message: message, to: to)
        expect(Telephony::Twilio::ProgrammableVoiceSender).to receive(:new).and_return(adapter)

        subject.send_confirmation_otp
      end
    end

    context 'for international SMS' do
      let(:channel) { :sms }
      let(:to) { '+81543543643' }

      it 'sends an authentication OTP with Twilio Verify' do
        verify_client = instance_double(Telephony::Twilio::VerifyClient)
        expect(verify_client).to receive(:send).with(otp: otp, to: to)
        expect(Telephony::Twilio::VerifyClient).to receive(:new).and_return(verify_client)

        subject.send_authentication_otp
      end

      it 'sends a confirmation OTP with Twilio Verify' do
        verify_client = instance_double(Telephony::Twilio::VerifyClient)
        expect(verify_client).to receive(:send).with(otp: otp, to: to)
        expect(Telephony::Twilio::VerifyClient).to receive(:new).and_return(verify_client)

        subject.send_confirmation_otp
      end
    end
  end
end
