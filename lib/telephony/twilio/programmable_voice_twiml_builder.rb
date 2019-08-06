require 'erb'
require 'forwardable'

module Telephony
  module Twilio
    class ProgrammableVoiceTwimlBuilder
      extend Forwardable

      attr_reader :message

      def initialize(message)
        @message = message
      end

      def_delegators :message, :locale, :repeat_url

      def call
        renderer = ERB.new(twiml_template)
        renderer.result(binding)
      end

      def message_body
        message.message
      end

      private

      def twiml_template
        template_file_path = File.join(
          File.dirname(__FILE__),
          'programmable_voice_message_twiml.xml.erb',
        )
        File.read(template_file_path)
      end
    end
  end
end
