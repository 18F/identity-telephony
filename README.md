This gem is meant to be used by [18f/identity-idp](https://github.com/18F/identity-idp) to send SMS messages and voice calls.
It provides an API and configuration that allows it to focus on selecting a provider and sending messages and allows the IDP to focus on what message to send.

# Configuration

This gem can be configured in this manner:

```ruby
Telephony.config do |c|
  c.adapter = :pinpoint

  c.pinpoint.add_sms_config do |sms|
    sms.region = 'us-west-2' # This is optional, us-west-2 is the default
    sms.application_id = 'fake-pinpoint-application-id-sms'
    sms.shortcode = '123456'
  end

  c.pinpoint.add_voice_config do |voice|
    voice.region = 'us-west-2' # This is optional, us-west-2 is the default
    voice.longcode_pool = ['+12223334444', '+15556667777']
  end
end
```

# Error handling

If the gem encounters a problem return a `Response` object with `success?` false and an `error` property.
This object can be used to render an error to the user like so:

```ruby

def create
  response = Telephony.end_authentication_otp(to: to, otp: otp, expiration: expiration, channel: :sms)
  return if response.success?

  flash[:error] = response.error.friendly_message
  render :new
end
```

# Test Adapter

The test adapter is meant to be used in the test environment to test what the gem is being used to send.

Recent text messages are pushed onto `Telephony::Test::Message.messages` and calls are pushed onto `Telephony::Call.calls`.
The stack of messages and calls can be flushed by using `Telephony::Test::Message.clear_messages` and `Telephony::Test::Call.clear_calls`.
Finally, the last sent OTP can be parsed from the stack of messages and calls using `Telephony::Test::Message.last_otp` and `Telephony::Test::Call.last_otp`.
