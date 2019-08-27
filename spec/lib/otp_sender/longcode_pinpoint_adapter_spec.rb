describe Telephony::OtpSender do
  context 'with the pinpoint adapter' do
    subject { described_class.new(to: to, otp: otp, expiration: expiration, channel: channel) }

    let(:to) { '+1 (202) 262-1234' }
    let(:otp) { '123456' }
    let(:expiration) { 5 }

    before do
      allow(Telephony.config).to receive(:adapter).and_return(:pinpoint_longcode)
    end

    context 'for SMS' do
      let(:channel) { :sms }

      it 'sends an authentication OTP with Pinpoint SMS using the longcode sender' do
        message = '123456 is your login.gov security code. Use this to continue signing in to your account. This code will expire in 5 minutes.'

        adapter = instance_double(Telephony::Pinpoint::LongcodeSmsSender)
        expect(adapter).to receive(:send).with(message: message, to: to)
        expect(Telephony::Pinpoint::LongcodeSmsSender).to receive(:new).and_return(adapter)

        subject.send_authentication_otp
      end

      it 'sends a confirmation OTP with Pinpoint SMS using the longcode sender' do
        message = '123456 is your login.gov confirmation code. Use this to confirm your phone number. This code will expire in 5 minutes.'

        adapter = instance_double(Telephony::Pinpoint::LongcodeSmsSender)
        expect(adapter).to receive(:send).with(message: message, to: to)
        expect(Telephony::Pinpoint::LongcodeSmsSender).to receive(:new).and_return(adapter)

        subject.send_confirmation_otp
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
