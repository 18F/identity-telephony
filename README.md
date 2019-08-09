This gem is meant to be used by [18f/identity-idp](https://github.com/18F/identity-idp) to send SMS messages and voice calls.
It provides an API and configuration that allows it to focus on selecting a provider and sending messages and allows the IDP to focus on what message to send.

# Configuration

This gem can be configured in this manner:

```ruby
Telephony.config do |c|
  c.adapter = :twilio
  c.twilio_numbers = ['12223334444', '15556667777']
  c.twilio_sid = 'example-twilio-sid'
  c.twilio_auth_token = 'example-twilio-auth-token'
  c.twilio_messaging_service_sid = 'example-twilio-messaging-service-sid'
  c.twilio_verify_api_key = 'example-twilio-verify-api-key'
  c.twilio_voice_callback_encryption_key = '#### 32 byte encryption key ####'
  c.twilio_voice_callback_base_url = 'https://example.com/api/twilo_voice'
  c.twilio_timeout = 5 # This is optional. The default is `5`
  c.twilio_record_voice = false # This is optional. The default is `false`
end
```

# Twilio Adapter

When the Twilio adapter is in use, the gem will use Twilio to send voice calls an SMSs.

For Twilio voice calls to work, the application needs to present a callback URL for Twilio to hit when the user picks up the phone.
This gem will build the URL from the configuration and handle parsing the params in the Twilio request, but the application will need to pass the URL for the gem for it to work.

That should look something like this:

```ruby
# config/routes.rb
match '/api/twilio/voice' => 'twilio/voice#show',
        via: %i[get post],
        as: :voice_otp,
        defaults: { format: :xml }

# app/twilio_voice_controller
class TwilioVoiceController < ApplicationController
  skip_before_action :verify_authenticity_token

  def show
    xml = Telephony::Twilio::ProgrammableVoiceMessage.from_callback(request.original_url)
    render xml: xml
  end
end
```

You will also probably want to use the `Rack::TwilioWebhookAuthentication` middleware to verify that the callback requests are actually originating from Twilio.

# Test Adapter

The test adapter is meant to be used in the test environment to test what the gem is being used to send.

Recent text messages are pushed onto `Telephony::Test::Message.messages` and calls are pushed onto `Telephony::Call.calls`.
The stack of messages and calls can be flushed by using `Telephony::Test::Message.clear_messages` and `Telephony::Test::Call.clear_calls`.
Finally, the last sent OTP can be parsed from the stack of messages and calls using `Telephony::Test::Message.last_otp` and `Telephony::Test::Call.last_otp`.
