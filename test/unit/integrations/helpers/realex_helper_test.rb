require 'test_helper'

class RealexHelperTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations

  def setup
    @required_options = {
      :amount => 50000,
      :currency => 'GBP',
      :merchant_id => 'testaccount',
      :secret => 'ae2b1fca515949e5d54fb22b8ed95575'
    }
    @helper = Realex::Helper.new('500','internet', @required_options.clone)
  end

  def test_basic_helper_fields
    assert_field 'MERCHANT_ID', 'testaccount'
    assert_field 'ACCOUNT', 'internet'
    assert_field 'ORDER_ID', '500'
    assert_field 'AMOUNT', '50000'
  end

  def test_setting_invalid_field
    fields = @helper.fields.dup
    @helper.return_url 'https://example.com'
    assert_equal fields, @helper.fields
  end

  def test_raises_without_required_options
    assert_raises(ArgumentError) { Realex::Helper.new('500', 'internet', @required_options.reject{|k,v| k == :amount}) }
    assert_raises(ArgumentError) { Realex::Helper.new('500', 'internet', @required_options.reject{|k,v| k == :currency}) }
    assert_raises(ArgumentError) { Realex::Helper.new('500', 'internet', @required_options.reject{|k,v| k == :secret}) }
    assert_raises(ArgumentError) { Realex::Helper.new('500', 'internet', @required_options.reject{|k,v| k == :merchant_id}) }
  end
end
