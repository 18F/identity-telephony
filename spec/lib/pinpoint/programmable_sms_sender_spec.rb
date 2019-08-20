describe Telephony::Pinpoint::ProgrammableSmsSender do
  it_behaves_like 'a pinpoint api client'

  describe '#send' do
    it 'initializes a pinpoint client and uses that to send a message' do
      client = instance_double(Aws::Pinpoint::Client)
      expect(Aws::Pinpoint::Client).to receive(:new).with(
        region: Telephony.config.pinpoint_region,
        access_key_id: Telephony.config.pinpoint_access_key_id,
        secret_access_key: Telephony.config.pinpoint_secret_access_key
      ).and_return(client)

      hash = {
        application_id: Telephony.config.pinpoint_application_id,
        message_request:
          {
            addresses:
              {
                '+1 (123) 456-7890' =>
                  {
                    channel_type: 'SMS',
                  },
              },
            message_configuration:
              {
                sms_message:
                  {
                    body: 'This is a test!',
                    message_type: 'TRANSACTIONAL',
                  },
              },
          },
      }

      expect(client).to receive(:send_messages).with(hash)
      subject.send(message: 'This is a test!', to: '+1 (123) 456-7890')
    end
  end
end
