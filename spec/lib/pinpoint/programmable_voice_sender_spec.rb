xdescribe Telephony::Pinpoint::ProgrammableVoiceSender do
  it_behaves_like 'a pinpoint api client'

  describe '#send' do
    it 'initializes a pinpoint client and uses that to place a call with a random number' do
      client = instance_double(Aws::Pinpoint::Client)
      expect(Aws::Pinpoint::Client).to receive(:new).with(
        Telephony.config.pinpoint_sid,
        Telephony.config.pinpoint_auth_token,
        nil,
        nil,
        instance_of(::Pinpoint::HTTP::Client)
      ).and_return(client)

      expect(Telephony.config.pinpoint_numbers).to receive(:sample).and_return('12223334444')

      calls = double
      expect(client).to receive(:calls).and_return(calls)
      expect(calls).to receive(:create) do |params|
        expect(params[:to]).to eq('+1 (123) 456-7890')
        expect(params[:from]).to eq('12223334444')
        expect(params[:record]).to eq(false)

        callback_message = Telephony::Pinpoint::ProgrammableVoiceMessage.from_callback(params[:url])

        expect(callback_message.message).to eq('This is a test!')
        expect(callback_message.repeat_count).to eq(5)
      end

      subject.send(message: 'This is a test!', to: '+1 (123) 456-7890')
    end
  end
end
