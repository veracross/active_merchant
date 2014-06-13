module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module Realex
        autoload :Helper, 'active_merchant/billing/integrations/realex/helper.rb'
        autoload :Notification, 'active_merchant/billing/integrations/realex/notification.rb'

        # Overwrite this if you want to change the ANS production url
        mattr_accessor :production_url
        self.production_url = 'https://epage.payandshop.com/epage.cgi'

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

        def self.notification(post, options = {})
          Notification.new(post, options)
        end
      end
    end
  end
end
