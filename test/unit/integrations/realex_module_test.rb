require 'test_helper'

class RealexModuleTest < Test::Unit::TestCase
  include ActionViewHelperTestHelper
  include ActiveMerchant::Billing::Integrations

  def test_notification_method
    assert_instance_of Realex::Notification, Realex.notification('ORDER_ID=44-0', :secret => 'ae2b1fca515949e5d54fb22b8ed95575')
  end

  def test_all_fields
    Time.stubs(:now).returns(Time.utc(2014,6,14,12,15,0))

    payment_service_for('44','internet', :service => :realex, :amount => 15700, :currency => 'GBP', :merchant_id => 'testaccount', :secret => 'ae2b1fca515949e5d54fb22b8ed95575'){|service|

      service.customer_id '123'
      service.description 'Foo Bar'
      service.attempt_number '0'

      service.add_secure_hash
    }

    inputs = [
      '<input id="MERCHANT_ID" name="MERCHANT_ID" type="hidden" value="testaccount" />',
      '<input id="ACCOUNT" name="ACCOUNT" type="hidden" value="internet" />',
      '<input id="TIMESTAMP" name="TIMESTAMP" type="hidden" value="20140614121500" />',
      '<input id="AUTO_SETTLE_FLAG" name="AUTO_SETTLE_FLAG" type="hidden" value="1" />',
      '<input id="AMOUNT" name="AMOUNT" type="hidden" value="15700" />',
      '<input id="CURRENCY" name="CURRENCY" type="hidden" value="GBP" />',
      '<input id="CUST_NUM" name="CUST_NUM" type="hidden" value="123" />',
      '<input id="COMMENT1" name="COMMENT1" type="hidden" value="Foo Bar" />',
      '<input id="ORDER_ID" name="ORDER_ID" type="hidden" value="44-0" />',
      '<input id="SHA1HASH" name="SHA1HASH" type="hidden" value="e967d55490bac2d6611fc4ab984b9e97844b6fe8" />'
    ]

    for input in inputs do
      if input =~ /name="[^"]+" type="hidden" value="[^"]+"/i
        assert @output_buffer.include?(input), 'didnt find ' + input + ' in ' + @output_buffer
      end
    end
  end

end
