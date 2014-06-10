require 'test_helper'

class MigsHelperTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations

  def setup
    @required_options = {
      :amount => 50000,
      :locale => 'en_US',
      :secret => '76AF3392002D202A60D0AB5F9D81653C',
      :access_code => '6447E199'
    }
    @helper = Migs::Helper.new('500','TESTANZTEST3', @required_options.clone)
  end

  def test_basic_helper_fields
    assert_field 'vpc_Merchant', 'TESTANZTEST3'
    assert_field 'vpc_Amount', '50000'
    assert_field 'vpc_MerchTxnRef', '500'
    assert_field 'vpc_Locale', 'en_US'
  end

  def test_address_mapping
    @helper.billing_address :address1 => '1 My Street',
                            :address2 => '',
                            :city => 'Leeds',
                            :state => 'Yorkshire',
                            :zip => 'LS2 7EE',
                            :country  => 'CA'
    assert_field 'vpc_AVS_Street_01', '1 My Street'
    assert_field 'vpc_AVS_City', 'Leeds'
    assert_field 'vpc_AVS_StateProv', 'Yorkshire'
    assert_field 'vpc_AVS_PostCode', 'LS2 7EE'
    assert_field 'vpc_AVS_Country', 'CA'
  end

  def test_unknown_address_mapping
    @helper.billing_address :farm => 'CA'
    assert_equal 10, @helper.fields.size
  end

  def test_unknown_mapping
    assert_nothing_raised do
      @helper.company_address :address => '500 Dwemthy Fox Road'
    end
  end

  def test_setting_invalid_address_field
    fields = @helper.fields.dup
    @helper.billing_address :street => 'My Street'
    assert_equal fields, @helper.fields
  end

  def test_raises_without_required_options
    assert_raises(ArgumentError) { Migs::Helper.new('500','TESTANZTEST3', @required_options.reject{|k,v| k == :locale}) }
    assert_raises(ArgumentError) { Migs::Helper.new('500','TESTANZTEST3', @required_options.reject{|k,v| k == :secret}) }
    assert_raises(ArgumentError) { Migs::Helper.new('500','TESTANZTEST3', @required_options.reject{|k,v| k == :access_code}) }
  end
end
