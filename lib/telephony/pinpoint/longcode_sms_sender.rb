module Telephony
  module Pinpoint
    class LongcodeSmsSender < SmsSender
      protected

      def origination_number
        Telephony.config.pinpoint_longcode_pool.sample
      end
    end
  end
end
