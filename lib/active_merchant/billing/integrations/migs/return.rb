require 'digest/md5'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:
      module Migs
        class Return < ActiveMerchant::Billing::Integrations::Return
          include RequiresParameters

          def initialize(query_string, options = {})
            requires!(options, :secret)
            super
            @valid = secure_hash_matches?
          end

          def message
            return 'Response from MiGS could not be validated' if not @valid
            params['vpc_Message']
          end

          def command
            params['vpc_Command']
          end

          def transaction_id
            params['vpc_TransactionNo']
          end

          def authorization_code
            params['vpc_AuthorizeId']
          end

          def description
            params['vpc_OrderInfo'].gsub(/^.*\//, '')
          end

          def order
            params['vpc_MerchTxnRef'].gsub(/-\d+$/, '')
          end

          def attempt_number
            params['vpc_MerchTxnRef'].gsub(/^\d+-/, '')
          end

          def response_code
            params['vpc_TxnResponseCode']
          end

          def merchant
            params['vpc_Merchant']
          end

          def receipt_number
            params['vpc_ReceiptNo']
          end

          def amount
            params['vpc_Amount'].to_i
          end

          def success?
            return false if not @valid
            params['vpc_TxnResponseCode'] == '0'
          end

          def cancelled?
            params['vpc_TxnResponseCode'] != '0'
          end

          def secure_hash
            params['vpc_SecureHash']
          end

          def avs_code
            params['vpc_AVSResultCode']
          end

          def cvv_code
            params['vpc_CSCResultCode']
          end

          def secure_hash_matches?
            return false if not params['vpc_SecureHash']
            response = params.clone
            response.delete('vpc_SecureHash')
            sorted_values = response.sort_by(&:to_s).map(&:last)
            input = @options[:secret] + sorted_values.join
            Digest::MD5.hexdigest(input).upcase == secure_hash
          end

          # Returns true if one of the following is true:
          #
          # - address and 9-digit zip matches
          # - address and 5-digit zip matches
          # - 5-digit zip matches, address not checked
          def avs_code_matches?
            return ['Y', 'X', 'P'].include? avs_code
          end

          def cvv_code_matches?
            return ['M'].include? cvv_code
          end
        end
      end
    end
  end
end
