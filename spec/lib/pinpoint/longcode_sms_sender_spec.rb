describe Telephony::Pinpoint::LongcodeSmsSender do
  it_behaves_like 'a pinpoint sms client'

  describe '#send' do
    it 'initializes a pinpoint client and uses that to send a message with a longcode' do
      expect(Aws::Pinpoint::Client).to receive(:new).
        with(
          region: Telephony.config.pinpoint.sms.region,
          access_key_id: Telephony.config.pinpoint.sms.access_key_id,
          secret_access_key: Telephony.config.pinpoint.sms.secret_access_key,
        ).
        and_return(Pinpoint::MockClient.new)
      expect(Telephony.config.pinpoint.sms.longcode_pool).to receive(:sample).
        and_return('+12223334444')

      subject.send(message: 'This is a test!', to: '+1 (123) 456-7890')

      expected_result = {
        application_id: Telephony.config.pinpoint.sms.application_id,
        message_request: {
          addresses: {
            '+1 (123) 456-7890' => { channel_type: 'SMS' },
          },
          message_configuration: {
            sms_message: {
              body: 'This is a test!',
              message_type: 'TRANSACTIONAL',
              origination_number: '+12223334444',
            },
          },
        },
      }
      expect(Pinpoint::MockClient.last_request).to eq(expected_result)
    end
  end
end
