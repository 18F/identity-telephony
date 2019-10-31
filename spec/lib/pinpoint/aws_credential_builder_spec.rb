describe Telephony::Pinpoint::AwsCredentialBuilder do
  subject { described_class.new(channel) }

  let(:credential_role_session_name) { nil }
  let(:credential_role_arn) { nil }
  let(:credential_external_id) { nil }
  let(:access_key_id) { nil }
  let(:secret_access_key) { nil }
  let(:region) { 'us-west-2' }

  shared_examples_for 'an AWS credential builder for a channel' do
    before do
      allow(Telephony.config.pinpoint.send(channel)).to receive(:credential_role_session_name).
          and_return(credential_role_session_name)
      allow(Telephony.config.pinpoint.send(channel)).to receive(:credential_role_arn).
        and_return(credential_role_arn)
      allow(Telephony.config.pinpoint.send(channel)).to receive(:credential_external_id).
        and_return(credential_external_id)
      allow(Telephony.config.pinpoint.send(channel)).to receive(:access_key_id).
        and_return(access_key_id)
      allow(Telephony.config.pinpoint.send(channel)).to receive(:secret_access_key).
        and_return(secret_access_key)
      allow(Telephony.config.pinpoint.send(channel)).to receive(:region).
        and_return(region)
    end

    context 'with assumed roles in the config' do
      let(:credential_role_session_name) { 'arn:123' }
      let(:credential_role_arn) { 'identity-idp' }
      let(:credential_external_id) { 'asdf1234' }

      it 'returns an assumed role credential' do
        sts_client = double(Aws::STS::Client)
        allow(Aws::STS::Client).to receive(:new).with(region: region).and_return(sts_client)
        expected_credential = instance_double(Aws::AssumeRoleCredentials)
        expect(Aws::AssumeRoleCredentials).to receive(:new).with(
          role_session_name: credential_role_session_name,
          role_arn: credential_role_arn,
          external_id: credential_external_id,
          client: sts_client,
        ).and_return(expected_credential)

        result = subject.call

        expect(result).to eq(expected_credential)
      end
    end

    context 'with aws credentials in the config' do
      let(:access_key_id) { 'fake-access-key-id' }
      let(:secret_access_key) { 'fake-secret-key-id' }

      it 'returns a plain old credential object' do
        result = subject.call

        expect(result).to be_a(Aws::Credentials)
        expect(result.access_key_id).to eq(access_key_id)
        expect(result.secret_access_key).to eq(secret_access_key)
      end
    end

    context 'with no credentials in the config' do
      it 'returns nil' do
        result = subject.call

        expect(result).to eq(nil)
      end
    end
  end

  context 'for the sms channel' do
    let(:channel) { :sms }

    it_behaves_like 'an AWS credential builder for a channel'
  end

  context 'for the voice channel' do
    let(:channel) { :voice }

    it_behaves_like 'an AWS credential builder for a channel'
  end
end
