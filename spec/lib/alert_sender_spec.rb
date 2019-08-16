describe Telephony::AlertSender do
  let(:configured_adapter) { :test }
  let(:recipient) { '+1 (202) 555-5000' }

  before do
    allow(Telephony.config).to receive(:adapter).and_return(configured_adapter)
    Telephony::Test::Message.clear_messages
  end

  describe 'send_account_reset_notice' do
    it 'sends the correct message' do
      subject.send_account_reset_notice(to: recipient, cancel_link: 'example.com')

      last_message = Telephony::Test::Message.messages.last
      expect(last_message.to).to eq(recipient)
      expect(last_message.body).to eq(
        I18n.t('account_reset_notice', cancel_link: 'example.com')
      )
    end
  end

  describe 'send_account_reset_cancellation_notice' do
    it 'sends the correct message' do
      subject.send_account_reset_cancellation_notice(to: recipient)

      last_message = Telephony::Test::Message.messages.last
      expect(last_message.to).to eq(recipient)
      expect(last_message.body).to eq(I18n.t('account_reset_cancellation_notice'))
    end
  end

  describe 'send_doc_auth_link' do
    it 'sends the correct message' do
      subject.send_doc_auth_link(to: recipient, link: 'example.com')

      last_message = Telephony::Test::Message.messages.last
      expect(last_message.to).to eq(recipient)
      expect(last_message.body).to eq(I18n.t('doc_auth_link', link: 'example.com'))
    end
  end

  describe 'send_personal_key_regeneration_notice' do
    it 'sends the correct message' do
      subject.send_personal_key_regeneration_notice(to: recipient)

      last_message = Telephony::Test::Message.messages.last
      expect(last_message.to).to eq(recipient)
      expect(last_message.body).to eq(I18n.t('personal_key_regeneration_notice'))
    end
  end

  describe 'send_personal_key_sign_in_notice' do
    it 'sends the correct message' do
      subject.send_personal_key_sign_in_notice(to: recipient)

      last_message = Telephony::Test::Message.messages.last
      expect(last_message.to).to eq(recipient)
      expect(last_message.body).to eq(I18n.t('personal_key_sign_in_notice'))
    end
  end

  describe 'send_join_keyword_response' do
    it 'sends the correct message' do
      subject.send_join_keyword_response(to: recipient)

      last_message = Telephony::Test::Message.messages.last
      expect(last_message.to).to eq(recipient)
      expect(last_message.body).to eq(I18n.t('join_keyword_response'))
    end
  end

  describe 'send_stop_keyword_response' do
    it 'sends the correct message' do
      subject.send_stop_keyword_response(to: recipient)

      last_message = Telephony::Test::Message.messages.last
      expect(last_message.to).to eq(recipient)
      expect(last_message.body).to eq(I18n.t('stop_keyword_response'))
    end
  end

  describe 'send_help_keyword_response' do
    it 'sends the correct message' do
      subject.send_help_keyword_response(to: recipient)

      last_message = Telephony::Test::Message.messages.last
      expect(last_message.to).to eq(recipient)
      expect(last_message.body).to eq(I18n.t('help_keyword_response'))
    end
  end

  context 'with the twilio adapter enabled' do
    let(:configured_adapter) { :twilio }

    it 'uses the twilio adapter to send messages' do
      adapter = instance_double(Telephony::Twilio::ProgrammableSmsSender)
      expect(adapter).to receive(:send).with(
        message: I18n.t('join_keyword_response'),
        to: recipient,
      )
      expect(Telephony::Twilio::ProgrammableSmsSender).to receive(:new).and_return(adapter)

      subject.send_join_keyword_response(to: recipient)
    end
  end
end
