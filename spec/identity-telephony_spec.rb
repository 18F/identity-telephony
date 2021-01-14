RSpec.describe Telephony do
  describe '.phone_type' do
    let(:phone_number) { '+18888675309' }
    subject(:phone_type) { Telephony.phone_type(phone_number) }

    context 'with test adapter' do
      before { Telephony.config { |c| c.adapter = :test } }

      it 'uses the test adapter' do
        expect(phone_type).to eq(:mobile)
      end
    end

    context 'with pinpoint adapter' do
      before do
        Telephony.config { |c| c.adapter = :pinpoint }

        Aws.config[:pinpoint] = {
          stub_responses: {
            phone_number_validate: {
              number_validate_response: { phone_type: 'VOIP' },
            },
          },
        }
      end

      it 'uses the pinpoint adapter' do
        expect(phone_type).to eq(:voip)
      end
    end
  end
end
