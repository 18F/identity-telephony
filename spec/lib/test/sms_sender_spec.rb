describe Telephony::Test::SmsSender do
  before do
    Telephony::Test::Message.clear_messages
  end

  subject(:sms_sender) {Telephony::Test::SmsSender.new }

  describe '#send' do
    it 'adds the message to the message stack' do
      message_body = 'This is a test'
      phone = '+1 (202) 555-5000'

      response = subject.send(message: message_body, to: phone)

      last_message = Telephony::Test::Message.messages.last

      expect(response.success?).to eq(true)
      expect(response.error).to eq(nil)
      expect(response.extra[:request_id]).to eq('fake-message-request-id')
      expect(response.extra[:message_id]).to eq('fake-message-id')
      expect(last_message.body).to eq(message_body)
      expect(last_message.to).to eq(phone)
    end

    it 'simulates a telephony error' do
      response = subject.send(message: 'test', to: '+1 (225) 555-1000')

      last_message = Telephony::Test::Message.messages.last

      expect(response.success?).to eq(false)
      expect(response.error).to eq(Telephony::TelephonyError.new('Simulated telephony error'))
      expect(response.extra[:request_id]).to eq('fake-message-request-id')
      expect(last_message).to eq(nil)
    end

    it 'simulates an invalid calling area error' do
      response = subject.send(message: 'test', to: '+1 (225) 555-2000')

      last_message = Telephony::Test::Message.messages.last

      expect(response.success?).to eq(false)
      expect(response.error).to eq(
        Telephony::InvalidCallingAreaError.new('Simulated calling area error'),
      )
      expect(response.extra[:request_id]).to eq('fake-message-request-id')
      expect(last_message).to eq(nil)
    end
  end

  describe '#phone_type' do
    subject(:phone_type) { sms_sender.phone_type(phone_number) }

    context 'with a phone number that does not generate errors' do
      let(:phone_number) { '+18888675309' }
      it { is_expected.to eq(:mobile) }
    end

    context 'with a phone number that generates errors' do
      let(:phone_number) { '+12255551000' }
      it { is_expected.to eq(:unknown) }
    end
  end
end
