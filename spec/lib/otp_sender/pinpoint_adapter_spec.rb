describe Telephony::OtpSender do
  context 'with the pinpoint adapter' do
    subject { described_class.new(to: to, otp: otp, expiration: expiration, channel: channel) }

    let(:to) { '+1 (202) 262-1234' }
    let(:otp) { '123456' }
    let(:expiration) { 5 }

    before do
      allow(Telephony.config).to receive(:adapter).and_return(:pinpoint)
    end

    context 'for SMS' do
      let(:channel) { :sms }

      it 'sends an authentication OTP with Pinpoint SMS' do
        message = '123456 is your login.gov security code. Use this to continue signing in to your account. This code will expire in 5 minutes.'

        adapter = instance_double(Telephony::Pinpoint::SmsSender)
        expect(adapter).to receive(:send).with(message: message, to: to)
        expect(Telephony::Pinpoint::SmsSender).to receive(:new).and_return(adapter)

        subject.send_authentication_otp
      end

      it 'sends a confirmation OTP with Pinpoint SMS' do
        message = '123456 is your login.gov confirmation code. Use this to confirm your phone number. This code will expire in 5 minutes.'

        adapter = instance_double(Telephony::Pinpoint::SmsSender)
        expect(adapter).to receive(:send).with(message: message, to: to)
        expect(Telephony::Pinpoint::SmsSender).to receive(:new).and_return(adapter)

        subject.send_confirmation_otp
      end

      context 'with Twilio verify override enabled' do
        let(:to) { '+81543543643' }

        before do
          allow(Telephony.config.twilio).to receive(:verify_override_for_intl_sms).and_return(true)
        end

        it 'sends international SMS with Twilio Verify' do
          verify_client = instance_double(Telephony::Twilio::VerifyClient)
          expect(verify_client).to receive(:send).with(otp: otp, to: to)
          expect(Telephony::Twilio::VerifyClient).to receive(:new).and_return(verify_client)

          subject.send_authentication_otp
        end
      end

      context 'with Twilio verify override disabled' do
        let(:to) { '+81543543643' }

        before do
          allow(Telephony.config.twilio).to receive(:verify_override_for_intl_sms).and_return(false)
        end

        it 'does sends international SMS with Pinpoint' do
          message = '123456 is your login.gov security code. Use this to continue signing in to your account. This code will expire in 5 minutes.'

          adapter = instance_double(Telephony::Pinpoint::SmsSender)
          expect(adapter).to receive(:send).with(message: message, to: to)
          expect(Telephony::Pinpoint::SmsSender).to receive(:new).and_return(adapter)

          subject.send_authentication_otp
        end
      end
    end

    context 'for voice' do
      let(:channel) { :voice }

      it 'sends an authentication OTP with Pinpoint Voice' do
        message = 'Hello! Your login.gov one time passcode is, 1, 2, 3, 4, 5, 6, again, your passcode is, 1, 2, 3, 4, 5, 6. This code expires in 5 minutes.'

        adapter = instance_double(Telephony::Pinpoint::VoiceSender)
        expect(adapter).to receive(:send).with(message: message, to: to)
        expect(Telephony::Pinpoint::VoiceSender).to receive(:new).and_return(adapter)

        subject.send_confirmation_otp
      end

      it 'sends a confirmation OTP with Pinpoint Voice' do
        message = 'Hello! Your login.gov one time passcode is, 1, 2, 3, 4, 5, 6, again, your passcode is, 1, 2, 3, 4, 5, 6. This code expires in 5 minutes.'

        adapter = instance_double(Telephony::Pinpoint::VoiceSender)
        expect(adapter).to receive(:send).with(message: message, to: to)
        expect(Telephony::Pinpoint::VoiceSender).to receive(:new).and_return(adapter)

        subject.send_confirmation_otp
      end
    end
  end
end
