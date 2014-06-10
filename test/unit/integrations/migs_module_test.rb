require 'test_helper'

class MigsModuleTest < Test::Unit::TestCase
  include ActionViewHelperTestHelper
  include ActiveMerchant::Billing::Integrations

  def test_return_method
    assert_instance_of Migs::Return, Migs.return('vpc_Command=pay', :secret => '76AF3392002D202A60D0AB5F9D81653C')
  end

  def test_all_fields
    payment_service_for('44','TESTANZTEST3', :service => :migs, :amount => 15700, :locale => 'en_US', :secret => '5816DF2E29819E43EA7C1F6E0DC2F1B5', :access_code => '6447E199'){|service|

      # These fields (billing_address and credit_card) are only if using
      # the three step payment method when collecting the billing
      # details before redirecting for 3-D secure handling.
      service.billing_address :zip      => '22222',
                              :city     => 'Arlington',
                              :state    => 'VA',
                              :country  => 'US',
                              :address1 => '1 Main St'

      service.credit_card :number             => '4005550000000001',
                          :expiry_month       => '05',
                          :expiry_year        => '2017',
                          :verification_value => '123',
                          :brand              => :visa

      service.attempt_number '0'
      service.description 'Foo Bars'
      service.return_url 'https://example.com/return'

      service.add_secure_hash
    }

    inputs = [
      '<input id="vpc_Merchant" name="vpc_Merchant" type="hidden" value="TESTANZTEST3" />',
      '<input id="vpc_Version" name="vpc_Version" type="hidden" value="1" />',
      '<input id="vpc_AccessCode" name="vpc_AccessCode" type="hidden" value="6447E199" />',
      '<input id="vpc_Locale" name="vpc_Locale" type="hidden" value="en_US" />',
      '<input id="vpc_VirtualPaymentClientURL" name="vpc_VirtualPaymentClientURL" type="hidden" value="https://migs.mastercard.com.au/vpcpay" />',
      '<input id="vpc_Command" name="vpc_Command" type="hidden" value="pay" />',
      '<input id="vpc_ReturnURL" name="vpc_ReturnURL" type="hidden" value="https://example.com/return" />',
      '<input id="vpc_gateway" name="vpc_gateway" type="hidden" value="ssl" />',
      '<input id="vpc_Amount" name="vpc_Amount" type="hidden" value="15700" />',
      '<input id="vpc_AVS_Street_01" name="vpc_AVS_Street_01" type="hidden" value="1 Main St" />',
      '<input id="vpc_AVS_City" name="vpc_AVS_City" type="hidden" value="Arlington" />',
      '<input id="vpc_AVS_StateProv" name="vpc_AVS_StateProv" type="hidden" value="VA" />',
      '<input id="vpc_AVS_PostCode" name="vpc_AVS_PostCode" type="hidden" value="22222" />',
      '<input id="vpc_AVS_Country" name="vpc_AVS_Country" type="hidden" value="US" />',
      '<input id="vpc_CardNum" name="vpc_CardNum" type="hidden" value="4005550000000001" />',
      '<input id="vpc_CardExp" name="vpc_CardExp" type="hidden" value="1705" />',
      '<input id="vpc_CardSecurityCode" name="vpc_CardSecurityCode" type="hidden" value="123" />',
      '<input id="vpc_card" name="vpc_card" type="hidden" value="Visa" />',
      '<input id="vpc_OrderInfo" name="vpc_OrderInfo" type="hidden" value="44-0/Foo Bars" />',
      '<input id="vpc_MerchTxnRef" name="vpc_MerchTxnRef" type="hidden" value="44-0" />',
      '<input id="vpc_SecureHash" name="vpc_SecureHash" type="hidden" value="1A08F392BF05F96C9CDC25FDA1A2B220" />'
    ]

    for input in inputs do
      if input =~ /name="[^"]+" type="hidden" value="[^"]+"/i
        assert @output_buffer.include?(input), 'didnt find ' + input + ' in ' + @output_buffer
      end
    end
  end

end
