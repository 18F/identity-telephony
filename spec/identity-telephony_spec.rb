RSpec.describe Telephony do
  describe '.voip_phone?' do
    let(:phone_number) { '+18888675309' }
    subject(:voip_phone?) { Telephony.voip_phone?(phone_number) }

    context 'with test adapter' do
      before { Telephony.config { |c| c.adapter = :test } }

      it 'uses the test adapter' do
        expect(voip_phone?).to eq(false)
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
        expect(voip_phone?).to eq(true)
      end
    end
  end
end
