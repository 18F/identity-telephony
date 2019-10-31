$LOAD_PATH.push File.expand_path('../lib', __FILE__)
require 'telephony/version'

Gem::Specification.new do |s|
  s.name = 'identity-telephony'
  s.version = Telephony::VERSION
  s.platform = Gem::Platform::RUBY
  s.authors = [
    'Jonathan Hooper <jonathan.hooper@gsa.gov>',
  ]
  s.email = 'hello@login.gov'
  s.homepage = 'http://github.com/18F/identity-telephony-client'
  s.summary = 'A gem for sending SMS and voice calls'
  s.description = 'This gem is used by login.gov to send SMSs and voice calls to users.'
  s.date = Time.now.utc.strftime('%Y-%m-%d')
  s.files = Dir.glob('app/**/*') + Dir.glob('lib/**/*') + [
    'LICENSE.md',
    'README.md',
    'Gemfile',
    'identity-telephony-client.gemspec',
  ]
  s.license = 'LICENSE'
  s.test_files = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables = `git ls-files -- bin/*`.split("\n").map { |f| File.basename(f) }
  s.require_paths = ['lib']
  s.rdoc_options = ['--charset=UTF-8']

  s.add_dependency('aws-sdk-pinpoint')
  s.add_dependency('aws-sdk-pinpointsmsvoice')
  s.add_dependency('i18n')
  s.add_dependency('twilio-ruby')
  s.add_dependency('typhoeus')

  s.add_development_dependency('i18n-tasks')
  s.add_development_dependency('irb')
  s.add_development_dependency('pry-byebug')
  s.add_development_dependency('rake')
  s.add_development_dependency('rubocop')
  s.add_development_dependency('rspec')
  s.add_development_dependency('webmock')
end
