require 'active_support/version' # for ActiveSupport2.3
require 'active_support/core_ext/float/rounding.rb' unless ActiveSupport::VERSION::MAJOR > 3 # Float#round(precision)
require 'digest/sha1'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module Realex
        class Helper < ActiveMerchant::Billing::Integrations::Helper
          include RequiresParameters

          # Options must include:
          #
          # - :amount => cents
          # - :currency
          # - :secret => Realex shared secret for hash
          # - :merchant_id => Realex MERCHANT_ID field
          #
          # Also, the method add_secure_hash should be called at the very end
          # of the block passed to payment_service_for.
          def initialize(order, account, options = {})
            requires!(options, :merchant_id, :secret, :amount, :currency)

            # The following elements need to be removed from params to not
            # trigger an error, but can't be added to the object yet since
            # the @fields Hash has not been set up yet via super()
            merchant_id = options.delete(:merchant_id)
            # For generating the secure hash
            @secret = options.delete(:secret)

            super

            add_field('TIMESTAMP', Time.now.utc.strftime('%Y%m%d%H%M%S'))
            add_field('AUTO_SETTLE_FLAG', '1')

            self.merchant_id = merchant_id
          end

          # Make sure the order id and attempt number are combined into
          # the order field as order-attempt_number

          def order=(value)
            field = mappings[:order]
            existing_value = @fields[field] || ""

            # Inserts the order id at the beginning of the field
            value = existing_value.gsub(/^(\d+)?(-\d+)?$/, "#{value}\\2")

            add_field(field, value)
          end

          def attempt_number(value)
            field = mappings[:order]
            existing_value = @fields[field] || ""

            # Adds the attempt number after the order id
            value = existing_value.gsub(/^(\d+)?(-\d+)?$/, "\\1-#{value}")

            add_field(field, value)
          end

          # This must be called at the end after all other fields have been added
          def add_secure_hash
            fields = ['TIMESTAMP', 'MERCHANT_ID', 'ORDER_ID', 'AMOUNT', 'CURRENCY']

            values = fields.map{|f| @fields[f] }
            hash1 = Digest::SHA1.hexdigest(values.join('.'))
            hash2 = Digest::SHA1.hexdigest(hash1 + '.' + @secret)

            add_field('SHA1HASH', hash2)
          end

          mapping :account, 'ACCOUNT'
          mapping :merchant_id, 'MERCHANT_ID'
          mapping :order, 'ORDER_ID'
          mapping :description, 'COMMENT1'
          mapping :customer_id, 'CUST_NUM'
          mapping :currency, 'CURRENCY'
          mapping :amount, 'AMOUNT'

        end
      end
    end
  end
end
