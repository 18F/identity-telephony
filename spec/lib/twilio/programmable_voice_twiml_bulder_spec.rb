require 'rexml/document'
require 'rexml/xpath'

describe Telephony::Twilio::ProgrammableVoiceTwimlBuilder do
  let(:message) { Telephony::Twilio::ProgrammableVoiceMessage.new(message: 'Test message') }

  subject { described_class.new(message) }

  describe '#call' do
    let(:twiml) { subject.call }
    let(:twiml_document) { REXML::Document.new(twiml) }

    context 'when there are repeats remaining' do
      it 'renders message twiml with a repeat message section' do
        message_node = REXML::XPath.first(twiml_document, '/Response/Say')
        expect(message_node.text.strip).to eq('Test message')
        expect(message_node.attributes['language']).to eq('en')

        repeat_node = REXML::XPath.first(twiml_document, '/Response/Gather')
        repeat_url = repeat_node.attributes['action']
        repeat_message = Telephony::Twilio::ProgrammableVoiceMessage.from_callback(repeat_url)
        expect(repeat_node.attributes['numDigits']).to eq('1')
        expect(repeat_message.message).to eq('Test message')
        expect(repeat_message.repeat_count).to eq(4)

        repeat_message_node = REXML::XPath.first(twiml_document, '/Response/Gather/Say')
        expect(repeat_message_node.text.strip).to eq('Press 1 to repeat this message.')
        expect(repeat_message_node.attributes['language']).to eq('en')
      end
    end

    context 'when there are not repeats remaining' do
      let(:message) do
        Telephony::Twilio::ProgrammableVoiceMessage.new(message: 'Test message', repeat_count: 0)
      end

      it 'renders message twiml without a repeat message section' do
        message_node = REXML::XPath.first(twiml_document, '/Response/Say')
        expect(message_node.text.strip).to eq('Test message')
        expect(message_node.attributes['language']).to eq('en')

        repeat_node = REXML::XPath.first(twiml_document, '/Response/Gather')
        expect(repeat_node).to eq(nil)
      end
    end

    context 'when the locale is non-english' do
      let(:message) do
        Telephony::Twilio::ProgrammableVoiceMessage.new(message: 'Test mensaje', locale: :es)
      end

      it 'renders the message in the correct language' do
        message_node = REXML::XPath.first(twiml_document, '/Response/Say')
        expect(message_node.text.strip).to eq('Test mensaje')
        expect(message_node.attributes['language']).to eq('es')

        repeat_node = REXML::XPath.first(twiml_document, '/Response/Gather')
        repeat_url = repeat_node.attributes['action']
        repeat_message = Telephony::Twilio::ProgrammableVoiceMessage.from_callback(repeat_url)
        expect(repeat_node.attributes['numDigits']).to eq('1')
        expect(repeat_message.message).to eq('Test mensaje')
        expect(repeat_message.repeat_count).to eq(4)
        expect(repeat_message.locale).to eq('es')

        repeat_message_node = REXML::XPath.first(twiml_document, '/Response/Gather/Say')
        expect(repeat_message_node.text.strip).to eq('Presione 1 para repetir este mensaje.')
        expect(repeat_message_node.attributes['language']).to eq('es')
      end
    end
  end
end
