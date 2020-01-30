describe Telephony::Twilio::ProgrammableVoiceSender do
  it_behaves_like 'a twilio api client'

  describe '#send' do
    it 'initializes a twilio client and uses that to place a call with a random number' do
      client = instance_double(::Twilio::REST::Client)
      expect(::Twilio::REST::Client).to receive(:new).with(
        Telephony.config.twilio.sid,
        Telephony.config.twilio.auth_token,
        nil,
        nil,
        instance_of(::Twilio::HTTP::Client),
      ).and_return(client)

      expect(Telephony.config.twilio.numbers).to receive(:sample).and_return('12223334444')

      calls = double
      expect(client).to receive(:calls).and_return(calls)
      expect(calls).to receive(:create) do |params|
        expect(params[:to]).to eq('+1 (123) 456-7890')
        expect(params[:from]).to eq('12223334444')
        expect(params[:record]).to eq(false)

        callback_message = Telephony::Twilio::ProgrammableVoiceMessage.from_callback(params[:url])

        expect(callback_message.message).to eq('This is a test!')
        expect(callback_message.repeat_count).to eq(5)
      end

      result = subject.send(message: 'This is a test!', to: '+1 (123) 456-7890')

      expect(result.success?).to eq(true)
      expect(result.error).to eq(nil)
    end
  end
end
