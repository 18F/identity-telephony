require 'i18n/tasks'
require 'pry-byebug'
require 'webmock/rspec'
require 'identity-telephony'

Dir[File.dirname(__FILE__) + '/support/*.rb'].sort.each { |file| require file }

# Setup some default configs
Telephony.config do |c|
  c.logger = Logger.new(nil)

  c.twilio.numbers = ['12223334444', '15556667777']
  c.twilio.sid = 'fake-twilio-sid'
  c.twilio.auth_token = 'fake-twilio-auth-token'
  c.twilio.messaging_service_sid = 'fake-twilio-messaging-service-sid'
  c.twilio.verify_api_key = 'fake-twilio-verify-api-key'
  c.twilio.voice_callback_encryption_key = Base64.strict_encode64('0' * 32)
  c.twilio.voice_callback_base_url = 'https://example.com/api/voice'

  c.pinpoint.add_sms_config do |sms|
    sms.region = 'fake-pinpoint-region-sms'
    sms.access_key_id = 'fake-pinpoint-access-key-id-sms'
    sms.secret_access_key = 'fake-pinpoint-secret-access-key-sms'
    sms.application_id = 'fake-pinpoint-application-id-sms'
    sms.shortcode = '123456'
    sms.longcode_pool = ['+12223334444', '+15556667777']
  end

  c.pinpoint.add_voice_config do |voice|
    voice.region = 'fake-pinpoint-region-voice'
    voice.access_key_id = 'fake-pinpoint-access-key-id-voice'
    voice.secret_access_key = 'fake-pinpoint-secret-access-key-voice'
    voice.longcode_pool = ['+12223334444', '+15556667777']
  end
end

RSpec.configure do |config|
  config.mock_with :rspec do |mocks|
    mocks.verify_partial_doubles = true
  end
  config.shared_context_metadata_behavior = :apply_to_host_groups
  config.filter_run_when_matching :focus
  config.example_status_persistence_file_path = "spec/examples.txt"
  config.warnings = true
  config.order = :random
  Kernel.srand config.seed

  config.before(:each) do
    Pinpoint::MockClient.reset!
  end
end

WebMock.disable_net_connect!

# Raise missing translation errors in the specs so that missing translations
# will trigger a test failure
I18n.exception_handler = lambda do |exception, _locale, _key, _options|
  raise exception
end
