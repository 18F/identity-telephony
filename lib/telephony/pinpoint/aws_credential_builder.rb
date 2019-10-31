module Telephony
  module Pinpoint
    class AwsCredentialBuilder
      def initialize(channel)
        @channel = channel
      end

      def call
        if pinpoint_config.credential_role_arn && pinpoint_config.credential_role_session_name
          build_assumed_role_credential
        elsif pinpoint_config.access_key_id && pinpoint_config.secret_access_key
          build_access_key_credential
        end
      end

      private

      attr_reader :channel

      def build_assumed_role_credential
        Aws::AssumeRoleCredentials.new(
          role_arn: pinpoint_config.credential_role_arn,
          role_session_name: pinpoint_config.credential_role_session_name,
          external_id: pinpoint_config.credential_external_id,
          client: Aws::STS::Client.new(region: pinpoint_config.region),
        )
      end

      def build_access_key_credential
        Aws::Credentials.new(
          pinpoint_config.access_key_id,
          pinpoint_config.secret_access_key,
        )
      end

      def pinpoint_config
        if channel.to_sym == :sms
          Telephony.config.pinpoint.sms
        elsif channel.to_sym == :voice
          Telephony.config.pinpoint.voice
        end
      end
    end
  end
end
