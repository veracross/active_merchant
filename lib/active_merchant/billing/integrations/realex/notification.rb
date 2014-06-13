require 'digest'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    module Integrations #:nodoc:

      module Realex
        class Notification < ActiveMerchant::Billing::Integrations::Notification
          include RequiresParameters

          def initialize(query_string, options = {})
            requires!(options, :secret)
            super
            @valid = secure_hash_matches?
          end

          def message
            return 'Response from Realex could not be validated' if not @valid

            case response_code
            when '00'
              'Successful'
            when /^[23][0-9]{2}/
              'Payment processor error - please try again later'
            when '600', '601', '603', '666'
              'Gateway error'
            else
              params['MESSAGE']
            end
          end

          def transaction_id
            params['PASREF']
          end

          def timestamp
            DateTime.strptime(params['TIMESTAMP'], '%Y%m%d%H%M%S')
          end

          # Since we combine the order and attempt_number together when the
          # request is sent, we need to split it apart on the way back
          def order
            params['ORDER_ID'].gsub(/-\d+$/, '')
          end

          def attempt_number
            params['ORDER_ID'].gsub(/^\d+-/, '')
          end

          def response_code
            params['RESULT']
          end

          def authorization_code
            params['AUTHCODE']
          end

          def gross
            params['AMOUNT'].to_f/100.0
          end

          def merchant_id
            params['MERCHANT_ID']
          end

          def description
            params['COMMENT1']
          end

          def success?
            return false if not @valid
            params['RESULT'] == '00'
          end

          def cancelled?
            params['RESULT'] != '00'
          end

          def secure_hash
            params['SHA1HASH'] || params['MD5HASH']
          end

          def avs_code
            params['AVSPOSTCODERESULT']
          end

          def cvv_code
            params['CVNRESULT']
          end

          def secure_hash_matches?
            return false if not secure_hash

            # Based on the C# implementation in NActiveMerchant
            hash_algo = params['SHA1HASH'] ? Digest::SHA1 : Digest::MD5

            fields = ['TIMESTAMP', 'MERCHANT_ID', 'ORDER_ID', 'RESULT', 'MESSAGE', 'PASREF', 'AUTHCODE']

            values = fields.map{|f| @params[f] }
            hash1 = hash_algo.hexdigest(values.join('.'))
            hash2 = hash_algo.hexdigest(hash1 + '.' + @options[:secret])

            hash2 == secure_hash
          end

          def avs_code_matches?
            return ['M'].include? avs_code
          end

          def cvv_code_matches?
            return ['M'].include? cvv_code
          end

        end
      end
    end
  end
end
