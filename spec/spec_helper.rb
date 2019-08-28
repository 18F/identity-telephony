require 'i18n/tasks'
require 'pry-byebug'
require 'webmock/rspec'
require 'identity-telephony'

Dir[File.dirname(__FILE__) + '/support/*.rb'].sort.each { |file| require file }

# Setup some default configs
Telephony.config do |c|
  c.twilio_numbers = ['12223334444', '15556667777']
  c.twilio_sid = 'fake-twilio-sid'
  c.twilio_auth_token = 'fake-twilio-auth-token'
  c.twilio_messaging_service_sid = 'fake-twilio-messaging-service-sid'
  c.twilio_verify_api_key = 'fake-twilio-verify-api-key'
  c.twilio_voice_callback_encryption_key = Base64.strict_encode64('0' * 32)
  c.twilio_voice_callback_base_url = 'https://example.com/api/voice'

  c.pinpoint_region = 'fake-pinpoint-region'
  c.pinpoint_access_key_id = 'fake-pinpoint-access-key-id'
  c.pinpoint_secret_access_key = 'fake-pinpoint-secret-access-key'
  c.pinpoint_application_id = 'fake-pinpoint-application-id'
  c.pinpoint_shortcode = '123456'
  c.pinpoint_longcode_pool = ['+12223334444', '+15556667777']
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
