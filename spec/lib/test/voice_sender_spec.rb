describe Telephony::Test::VoiceSender do
  before do
    Telephony::Test::Message.clear_messages
  end

  describe '#send' do
    it 'adds the call to the call stack' do
      call_body = 'This is a test'
      phone = '+1 (202) 555-5000'

      response = subject.send(message: call_body, to: phone)

      last_call = Telephony::Test::Call.calls.last

      expect(last_call.body).to eq(call_body)
      expect(last_call.to).to eq(phone)
      expect(response.success?).to eq(true)
      expect(response.error).to eq(nil)
      expect(response.extra[:request_id]).to eq('fake-message-request-id')
    end
  end
end
