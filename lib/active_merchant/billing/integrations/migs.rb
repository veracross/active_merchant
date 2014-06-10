module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module Migs
        autoload :Helper, 'active_merchant/billing/integrations/migs/helper.rb'
        autoload :Return, 'active_merchant/billing/integrations/migs/return.rb'

        # Overwrite this if you want to change the ANS production url
        mattr_accessor :production_url
        self.production_url = 'https://migs.mastercard.com.au/vpcpay'

        def self.service_url
          mode = ActiveMerchant::Billing::Base.integration_mode
          case mode
          when :production
            self.production_url
          # There is no test URL
          when :test
            self.production_url
          else
            raise StandardError, "Integration mode set to an invalid value: #{mode}"
          end
        end

        def self.return(query_string, options = {})
          Return.new(query_string, options)
        end
      end
    end
  end
end
