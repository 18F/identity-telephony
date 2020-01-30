describe Telephony::Twilio::ProgrammableSmsSender do
  it_behaves_like 'a twilio api client'

  describe '#send' do
    it 'initializes a twilio client and uses that to send a message' do
      client = instance_double(::Twilio::REST::Client)
      expect(::Twilio::REST::Client).to receive(:new).with(
        Telephony.config.twilio.sid,
        Telephony.config.twilio.auth_token,
        nil,
        nil,
        instance_of(::Twilio::HTTP::Client),
      ).and_return(client)

      messages = double
      expect(client).to receive(:messages).and_return(messages)
      expect(messages).to receive(:create).with(
        messaging_service_sid: Telephony.config.twilio.messaging_service_sid,
        to: '+1 (123) 456-7890',
        body: 'This is a test!',
      )

      result = subject.send(message: 'This is a test!', to: '+1 (123) 456-7890')

      expect(result.success?).to eq(true)
      expect(result.error).to eq(nil)
    end
  end
end
