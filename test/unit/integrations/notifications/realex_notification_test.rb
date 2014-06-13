require 'test_helper'

class RealexTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations

  def setup
    @options = {:secret => 'ae2b1fca515949e5d54fb22b8ed95575'}
  end

  def test_no_secret
    assert_raises(ArgumentError) { Realex::Notification.new('ORDER_ID=44', {}) }
  end

  def test_successful_purchase
    r = Realex::Notification.new(successful_purchase, @options)
    assert r.success?
    assert_equal 'Successful', r.message
  end

  def test_failed_purchase
    r = Realex::Notification.new(failed_purchase, @options)
    assert !r.success?
    assert_equal 'Transaction blocked by merchant configuration. Please contact the merchant.', r.message
  end

  def test_bogus_hash
    r = Realex::Notification.new(failed_purchase.sub('791781439ae99ae2a8686d623ac7beab95c863ba', '1234'), @options)
    assert !r.success?
    assert_equal 'Response from Realex could not be validated', r.message
  end

  def test_attributes
    r = Realex::Notification.new(successful_purchase, @options)

    assert_equal 'Successful', r.message
    assert_equal '111', r.order
    assert_equal '0', r.attempt_number
    assert_equal 'Test Transaction', r.description
    assert_equal '19025624668132180', r.transaction_id
    assert_equal '00', r.response_code
    assert_equal 'testaccount', r.merchant_id
    assert_equal '491574', r.authorization_code
    assert_equal 220.0, r.gross
    assert_equal 22000, r.gross_cents
    assert_equal true, r.success?
    assert_equal false, r.cancelled?
    assert_equal 'f31d0f13de38a029a9cf0637118816cd26375299', r.secure_hash
    assert_equal 'M', r.avs_code
    assert_equal 'M', r.cvv_code
    assert_equal true, r.secure_hash_matches?
    assert_equal true, r.avs_code_matches?
    assert_equal true, r.cvv_code_matches?
  end

  private
  def successful_purchase
    'AMOUNT=22000&MERCHANT_ID=testaccount&ACCOUNT=internet&TIMESTAMP=20140614121500&ORDER_ID=111-0&COMMENT1=Test+Transaction&SHA1HASH=f31d0f13de38a029a9cf0637118816cd26375299&RESULT=00&AUTHCODE=491574&MESSAGE=AUTH+CODE%3a491574&PASREF=19025624668132180&AVSPOSTCODERESULT=M&AVSADDRESSRESULT=I&CVNRESULT=M&BATCHID=197737&ECI=5&CAVV=FFFBCWdxCAEjRWeCclZxAAAFFFF%3d&XID=IzafGj9aw9qypiQgXq4nNszETd0%3d&pas_uuid=626ecc4933984d712211f1158d2cb690'
  end

  def failed_purchase
    'AMOUNT=22000&MERCHANT_ID=testaccount&ACCOUNT=internet&TIMESTAMP=20140614121500&ORDER_ID=111-0&COMMENT1=Test+Transaction&SHA1HASH=791781439ae99ae2a8686d623ac7beab95c863ba&RESULT=110&AUTHCODE=&MESSAGE=Transaction+blocked+by+merchant+configuration.+Please+contact+the+merchant.&PASREF=&AVSPOSTCODERESULT=&AVSADDRESSRESULT=&CVNRESULT=&BATCHID=-1&ECI=&CAVV=&XID=&pas_uuid=039793bef1914167b2b35d85ff40bfc7'
  end
end
