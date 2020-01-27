describe Telephony::Test::SmsSender do
  before do
    Telephony::Test::Message.clear_messages
  end

  describe '#send' do
    it 'adds the message to the message stack' do
      message_body = 'This is a test'
      phone = '+1 (202) 555-5000'

      response = subject.send(message: message_body, to: phone)

      last_message = Telephony::Test::Message.messages.last

      expect(response.success?).to eq(true)
      expect(response.error).to eq(nil)
      expect(response.extra[:request_id]).to eq('fake-message-request-id')
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
end
