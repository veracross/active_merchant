require 'test_helper'

class MigsReturnTest < Test::Unit::TestCase
  include ActiveMerchant::Billing::Integrations

  def setup
    @options = {:secret => '76AF3392002D202A60D0AB5F9D81653C'}
  end

  def test_no_secret
    assert_raises(ArgumentError) { Migs::Return.new('vpc_Command=pay', {}) }
  end

  def test_successful_purchase
    r = Migs::Return.new(successful_purchase, @options)
    assert r.success?
    assert_equal 'Approved', r.message
  end
  
  def test_failed_purchase
    r = Migs::Return.new(failed_purchase, @options)
    assert !r.success?
    assert_equal 'Transaction was blocked by the Payment Server because it did not pass all risk checks.', r.message
  end
  
  def test_bogus_hash
    r = Migs::Return.new(failed_purchase.sub('F72F83C75DEEC95CCE4B5C9E559B2570', '1234'), @options)
    assert !r.success?
    assert_equal 'Response from MiGS could not be validated', r.message
  end

  def test_attributes
    r = Migs::Return.new(successful_purchase, @options)

    assert_equal 'Approved', r.message
    assert_equal '111', r.order
    assert_equal '0', r.attempt_number
    assert_equal 'Test', r.description
    assert_equal 'pay', r.command
    assert_equal '1591791', r.transaction_id
    assert_equal '0', r.response_code
    assert_equal 'TESTANZTEST3', r.merchant
    assert_equal '140614346331', r.receipt_number
    assert_equal 100, r.amount
    assert_equal true, r.success?
    assert_equal false, r.cancelled?
    assert_equal '033EE8FF47BA32217632D22DAE96F777', r.secure_hash
    assert_equal 'Unsupported', r.avs_code
    assert_equal 'Unsupported', r.cvv_code
    assert_equal true, r.secure_hash_matches?
    assert_equal false, r.avs_code_matches?
    assert_equal false, r.cvv_code_matches?
  end

  private
  def successful_purchase
    'vpc_3DSXID=ozQaTQcCH747kdbg58a1RdIonw0%3D&vpc_3DSenrolled=N&vpc_AVSResultCode=Unsupported&vpc_AVS_City=Newbury&vpc_AVS_Country=USA&vpc_AVS_PostCode=01951&vpc_AVS_StateProv=MA&vpc_AcqAVSRespCode=Unsupported&vpc_AcqCSCRespCode=Unsupported&vpc_AcqResponseCode=00&vpc_Amount=100&vpc_AuthorizeId=346331&vpc_BatchNo=20140614&vpc_CSCResultCode=Unsupported&vpc_Card=VC&vpc_Command=pay&vpc_Locale=en_IN&vpc_MerchTxnRef=111-0&vpc_Merchant=TESTANZTEST3&vpc_Message=Approved&vpc_OrderInfo=111-0%2FTest&vpc_ReceiptNo=140614346331&vpc_SecureHash=033EE8FF47BA32217632D22DAE96F777&vpc_TransactionNo=1591791&vpc_TxnResponseCode=0&vpc_VerSecurityLevel=06&vpc_VerStatus=E&vpc_VerType=3DS&vpc_Version=1'
  end

  def failed_purchase
    'vpc_3DSXID=sHIATs2a%2BVkk7lK%2BQNmKswA8qOg%3D&vpc_3DSenrolled=N&vpc_AVSResultCode=Unsupported&vpc_AVS_City=Newbury&vpc_AVS_Country=USA&vpc_AVS_PostCode=01951&vpc_AVS_StateProv=Massachusetts&vpc_AcqAVSRespCode=Unsupported&vpc_AcqCSCRespCode=Unsupported&vpc_Amount=100&vpc_BatchNo=20140613&vpc_CSCResultCode=Unsupported&vpc_Card=VC&vpc_CardNum=xxxxxxxxxxxx0001&vpc_Command=pay&vpc_Locale=en_US&vpc_MerchTxnRef=111-0&vpc_Merchant=TESTANZTEST3&vpc_Message=Transaction+was+blocked+by+the+Payment+Server+because+it+did+not+pass+all+risk+checks.&vpc_OrderInfo=111-0%2FTest&vpc_SecureHash=F72F83C75DEEC95CCE4B5C9E559B2570&vpc_TransactionNo=605&vpc_TxnResponseCode=B&vpc_VerSecurityLevel=06&vpc_VerStatus=E&vpc_VerType=3DS&vpc_Version=1'
  end
end
