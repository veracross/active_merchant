require 'test_helper'

class BlueSnapTest < Test::Unit::TestCase
  include CommStub

  def setup
    @gateway = BlueSnapGateway.new(api_username: 'login', api_password: 'password')
    @credit_card = credit_card
    @ach = check
    @amount = 100
    @options = { order_id: '1' }
  end

  def test_successful_purchase
    @gateway.expects(:raw_ssl_request).returns(successful_purchase_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_success response
    assert_equal '1012082839', response.authorization
  end

  def test_successful_ach_purchase
    @gateway.expects(:raw_ssl_request).returns(successful_ach_purchase_response)

    response = @gateway.purchase(@amount, @ach, @options)
    assert_success response
    assert_equal '38504784', response.authorization
  end

  def test_failed_purchase
    @gateway.expects(:raw_ssl_request).returns(failed_purchase_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal '14002', response.error_code
  end

  def test_successful_authorize
    response = stub_comms(@gateway, :raw_ssl_request) do
      @gateway.authorize(@amount, @credit_card, @options)
    end.check_request do |type, endpoint, data, headers|
      assert_match '<storeCard>false</storeCard>', data
    end.respond_with(successful_authorize_response)
    assert_success response
    assert_equal '1012082893', response.authorization
  end

  def test_failed_authorize
    @gateway.expects(:raw_ssl_request).returns(failed_authorize_response)

    response = @gateway.authorize(@amount, @credit_card, @options)
    assert_failure response
    assert_equal '14002', response.error_code
  end

  def test_successful_capture
    @gateway.expects(:raw_ssl_request).returns(successful_capture_response)

    response = @gateway.capture(@amount, 'Authorization')
    assert_success response
    assert_equal '1012082881', response.authorization
  end

  def test_failed_capture
    @gateway.expects(:raw_ssl_request).returns(failed_capture_response)

    response = @gateway.capture(@amount, 'Authorization')
    assert_failure response
    assert_equal '20008', response.error_code
  end

  def test_successful_refund
    @gateway.expects(:raw_ssl_request).returns(successful_refund_response)

<<<<<<< HEAD
    response = @gateway.refund(@amount, "1012082839")
    assert_success response
    assert_equal 204, response.params["code"].to_i
=======
    response = @gateway.refund(@amount, 'Authorization')
    assert_success response
    assert_equal '1012082907', response.authorization
>>>>>>> upstream/master
  end

  def test_failed_refund
    @gateway.expects(:raw_ssl_request).returns(failed_refund_response)

    response = @gateway.refund(@amount, 'Authorization')
    assert_failure response
    assert_equal '20008', response.error_code
  end

  def test_successful_void
    @gateway.expects(:raw_ssl_request).returns(successful_void_response)

    response = @gateway.void("Authorization", credit_card)
    assert_success response
    assert_equal '1012082919', response.authorization
  end

  def test_failed_void
    @gateway.expects(:raw_ssl_request).returns(failed_void_response)

    response = @gateway.void("Authorization", credit_card)
    assert_failure response
    assert_equal '20008', response.error_code
  end

  def test_successful_verify
    @gateway.expects(:raw_ssl_request).returns(successful_verify_response)

    response = @gateway.verify(@credit_card, @options)
    assert_success response
    assert_equal '1012082929', response.authorization
  end

  def test_failed_verify
    @gateway.expects(:raw_ssl_request).returns(failed_verify_response)

    response = @gateway.verify(@credit_card, @options)
    assert_failure response
    assert_equal '14002', response.error_code
  end

  def test_successful_store
    @gateway.expects(:raw_ssl_request).returns(successful_store_response)

    response = @gateway.store(@credit_card, @options)
    assert_success response
    assert_equal '20936441', response.authorization
  end

  def test_failed_store
    @gateway.expects(:raw_ssl_request).returns(failed_store_response)

    response = @gateway.store(@credit_card, @options)
    assert_failure response
    assert_equal '14002', response.error_code
  end

  def test_currency_added_correctly
    stub_comms(@gateway, :raw_ssl_request) do
      @gateway.purchase(@amount, @credit_card, @options.merge(currency: 'CAD'))
    end.check_request do |method, url, data|
      assert_match(/<currency>CAD<\/currency>/, data)
    end.respond_with(successful_purchase_response)
  end

  def test_verify_good_credentials
    @gateway.expects(:raw_ssl_request).returns(credentials_are_legit_response)
    assert @gateway.verify_credentials
  end

  def test_verify_bad_credentials
    @gateway.expects(:raw_ssl_request).returns(credentials_are_bogus_response)
    assert !@gateway.verify_credentials
  end

  def test_failed_forbidden_response
    @gateway.expects(:raw_ssl_request).returns(forbidden_response)

    response = @gateway.purchase(@amount, @credit_card, @options)
    assert_failure response
    assert_equal '<xml>You are not authorized to perform this request due to inappropriate role permissions.</xml>', response.message
  end

  def test_scrub
    assert @gateway.supports_scrubbing?
    assert_equal @gateway.scrub(pre_scrubbed), post_scrubbed
  end

  private

  def pre_scrubbed
    %q{
        opening connection to sandbox.bluesnap.com:443...
        starting SSL for sandbox.bluesnap.com:443...
        <- "POST /services/2/transactions HTTP/1.1\r\nContent-Type: application/xml\r\nAuthorization: Basic QVBJXzE0NjExNzM3MTY2NTc2NzM0MDQyMzpuZll3VHg4ZkZBdkpxQlhjeHF3Qzg=\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: */*\r\nUser-Agent: Ruby\r\nConnection: close\r\nHost: sandbox.bluesnap.com\r\nContent-Length: 683\r\n\r\n"
        <- "<card-transaction xmlns=\"http://ws.plimus.com\">\n  <card-transaction-type>AUTH_CAPTURE</card-transaction-type>\n  <recurring-transaction>RECURRING</recurring-transaction>\n  <amount>1.00</amount>\n  <currency>USD</currency>\n  <card-holder-info>\n    <first-name>Longbob</first-name>\n    <last-name>Longsen</last-name>\n    <country>CA</country>\n    <state>ON</state>\n    <city>Ottawa</city>\n    <zip>K1C2N6</zip>\n  </card-holder-info>\n  <transaction-fraud-info/>\n  <credit-card>\n    <card-number>4263982640269299</card-number>\n    <security-code>123</security-code>\n    <expiration-month>9</expiration-month>\n    <expiration-year>2017</expiration-year>\n  </credit-card>\n</card-transaction>"
        -> "HTTP/1.1 200 OK\r\n"
        -> "Set-Cookie: JSESSIONID=156258FCEC747EFAEA6FE909FDF0004A; Path=/services/; Secure; HttpOnly\r\n"
        -> "Content-Encoding: gzip\r\n"
        -> "\x1F\x8B\b\x00\x00\x00\x00\x00\x00\x03mS]\x8F\xDA0\x10|\xCF\xAF@\xA9\xD47c\xA0\x1F:Z\xE3\x13\xCD\xD1\x16\xF5\xC4U\x81\xF4\xB52\xB1\xE1,%v\xE4u\xB8K"
        Conn close
    }
  end

  def post_scrubbed
    %q{
        opening connection to sandbox.bluesnap.com:443...
        starting SSL for sandbox.bluesnap.com:443...
        <- "POST /services/2/transactions HTTP/1.1\r\nContent-Type: application/xml\r\nAuthorization: Basic [FILTERED]=\r\nAccept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3\r\nAccept: */*\r\nUser-Agent: Ruby\r\nConnection: close\r\nHost: sandbox.bluesnap.com\r\nContent-Length: 683\r\n\r\n"
        <- "<card-transaction xmlns=\"http://ws.plimus.com\">\n  <card-transaction-type>AUTH_CAPTURE</card-transaction-type>\n  <recurring-transaction>RECURRING</recurring-transaction>\n  <amount>1.00</amount>\n  <currency>USD</currency>\n  <card-holder-info>\n    <first-name>Longbob</first-name>\n    <last-name>Longsen</last-name>\n    <country>CA</country>\n    <state>ON</state>\n    <city>Ottawa</city>\n    <zip>K1C2N6</zip>\n  </card-holder-info>\n  <transaction-fraud-info/>\n  <credit-card>\n    <card-number>[FILTERED]</card-number>\n    <security-code>[FILTERED]</security-code>\n    <expiration-month>9</expiration-month>\n    <expiration-year>2017</expiration-year>\n  </credit-card>\n</card-transaction>"
        -> "HTTP/1.1 200 OK\r\n"
        -> "Set-Cookie: JSESSIONID=156258FCEC747EFAEA6FE909FDF0004A; Path=/services/; Secure; HttpOnly\r\n"
        -> "Content-Encoding: gzip\r\n"
        -> "\x1F\x8B\b\x00\x00\x00\x00\x00\x00\x03mS]\x8F\xDA0\x10|\xCF\xAF@\xA9\xD47c\xA0\x1F:Z\xE3\x13\xCD\xD1\x16\xF5\xC4U\x81\xF4\xB52\xB1\xE1,%v\xE4u\xB8K"
        Conn close
    }
  end

  def successful_purchase_response
    MockResponse.succeeded <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <card-transaction xmlns="http://ws.plimus.com">
      <card-transaction-type>AUTH_CAPTURE</card-transaction-type>
      <transaction-id>1012082839</transaction-id>
      <recurring-transaction>ECOMMERCE</recurring-transaction>
      <soft-descriptor>BLS*Spreedly</soft-descriptor>
      <amount>1.00</amount>
      <currency>USD</currency>
      <card-holder-info>
          <first-name>Longbob</first-name>
          <last-name>Longsen</last-name>
          <country>CA</country>
          <state>ON</state>
          <city>Ottawa</city>
          <zip>K1C2N6</zip>
      </card-holder-info>
      <credit-card>
          <card-last-four-digits>9299</card-last-four-digits>
          <card-type>VISA</card-type>
          <card-sub-type>CREDIT</card-sub-type>
      </credit-card>
      <processing-info>
          <processing-status>success</processing-status>
          <cvv-response-code>ND</cvv-response-code>
          <avs-response-code-zip>U</avs-response-code-zip>
          <avs-response-code-address>U</avs-response-code-address>
          <avs-response-code-name>U</avs-response-code-name>
      </processing-info>
      </card-transaction>
    XML
  end

  def successful_ach_purchase_response
    MockResponse.succeeded <<-XML
    <?xml version="1.0" encoding="UTF-8"?>
    <alt-transaction xmlns="http://ws.plimus.com">
       <transaction-id>38504784</transaction-id>
       <soft-descriptor>ABC COMPANY</soft-descriptor>
       <amount>100.00</amount>
       <currency>USD</currency>
       <payer-info>
          <first-name>John</first-name>
          <last-name>Doe</last-name>
          <zip>12345</zip>
          <phone>1234567890</phone>
       </payer-info>
       <ecp-transaction>
          <account-number>4099999992</account-number>
          <routing-number>011075150</routing-number>
          <account-type>CONSUMER_CHECKING</account-type>
       </ecp-transaction>
       <processing-info>
          <processing-status>SUCCESS</processing-status>
       </processing-info>
    </alt-transaction>
    XML
  end

  def failed_purchase_response
    body = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <messages xmlns="http://ws.plimus.com">
        <message>
          <error-name>INCORRECT_INFORMATION</error-name>
          <code>14002</code>
          <description>Transaction failed  because of payment processing failure.: 430285 - Authorization has failed for this transaction. Please try again or contact your bank for assistance</description>
        </message>
      </messages>
    XML

    MockResponse.failed(body, 400)
  end

  def successful_authorize_response
    MockResponse.succeeded <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <card-transaction xmlns="http://ws.plimus.com">
      <card-transaction-type>AUTH_ONLY</card-transaction-type>
      <transaction-id>1012082893</transaction-id>
      <recurring-transaction>ECOMMERCE</recurring-transaction>
      <soft-descriptor>BLS*Spreedly</soft-descriptor>
      <amount>1.00</amount>
      <currency>USD</currency>
      <card-holder-info>
          <first-name>Longbob</first-name>
          <last-name>Longsen</last-name>
          <country>CA</country>
          <state>ON</state>
          <city>Ottawa</city>
          <zip>K1C2N6</zip>
      </card-holder-info>
      <credit-card>
          <card-last-four-digits>9299</card-last-four-digits>
          <card-type>VISA</card-type>
          <card-sub-type>CREDIT</card-sub-type>
      </credit-card>
      <processing-info>
          <processing-status>success</processing-status>
          <cvv-response-code>ND</cvv-response-code>
          <avs-response-code-zip>U</avs-response-code-zip>
          <avs-response-code-address>U</avs-response-code-address>
          <avs-response-code-name>U</avs-response-code-name>
      </processing-info>
      </card-transaction>
    XML
  end

  def failed_authorize_response
    body = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <messages xmlns="http://ws.plimus.com">
      <message>
          <error-name>INCORRECT_INFORMATION</error-name>
          <code>14002</code>
          <description>Transaction failed  because of payment processing failure.: 430285 - Authorization has failed for this transaction. Please try again or contact your bank for assistance</description>
      </message>
      </messages>
    XML
    MockResponse.failed(body, 400)
  end

  def successful_capture_response
    MockResponse.succeeded <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <card-transaction xmlns="http://ws.plimus.com">
      <card-transaction-type>CAPTURE</card-transaction-type>
      <transaction-id>1012082881</transaction-id>
      <recurring-transaction>ECOMMERCE</recurring-transaction>
      <soft-descriptor>BLS*Spreedly</soft-descriptor>
      <amount>1.00</amount>
      <currency>USD</currency>
      <card-holder-info>
          <first-name>Longbob</first-name>
          <last-name>Longsen</last-name>
          <country>ca</country>
          <state>ON</state>
          <city>Ottawa</city>
          <zip>K1C2N6</zip>
      </card-holder-info>
      <credit-card>
          <card-last-four-digits>9299</card-last-four-digits>
          <card-type>VISA</card-type>
          <card-sub-type>CREDIT</card-sub-type>
      </credit-card>
      <processing-info>
          <processing-status>SUCCESS</processing-status>
          <cvv-response-code>ND</cvv-response-code>
          <avs-response-code-zip>U</avs-response-code-zip>
          <avs-response-code-address>U</avs-response-code-address>
          <avs-response-code-name>U</avs-response-code-name>
      </processing-info>
      </card-transaction>
    XML
  end

  def failed_capture_response
    body = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <messages xmlns="http://ws.plimus.com">
      <message>
          <error-name>TRANSACTION_ID_REQUIRED</error-name>
          <code>20008</code>
          <description>Transaction operation cannot be completed due to missing transaction ID parameter.</description>
      </message>
      </messages>
    XML
    MockResponse.failed(body, 400)
  end

  def successful_refund_response
    MockResponse.new(204, 'OK', '')
  end

  def failed_refund_response
    body = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <messages xmlns="http://ws.plimus.com">
         <message>
            <error-name>TRANSACTION_ID_REQUIRED</error-name>
            <code>20008</code>
            <description>Transaction operation cannot be completed due to missing transaction ID parameter.</description>
         </message>
      </messages>
    XML
    MockResponse.failed(body, 400)
  end

  def successful_void_response
    MockResponse.succeeded <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <card-transaction xmlns="http://ws.plimus.com">
         <card-transaction-type>AUTH_REVERSAL</card-transaction-type>
         <transaction-id>1012082919</transaction-id>
         <recurring-transaction>ECOMMERCE</recurring-transaction>
         <soft-descriptor>BLS*Spreedly</soft-descriptor>
         <amount>1.00</amount>
         <currency>USD</currency>
         <card-holder-info>
            <first-name>Longbob</first-name>
            <last-name>Longsen</last-name>
            <country>ca</country>
            <state>ON</state>
            <city>Ottawa</city>
            <zip>K1C2N6</zip>
         </card-holder-info>
         <credit-card>
            <card-last-four-digits>9299</card-last-four-digits>
            <card-type>VISA</card-type>
            <card-sub-type>CREDIT</card-sub-type>
         </credit-card>
         <processing-info>
            <processing-status>SUCCESS</processing-status>
            <cvv-response-code>ND</cvv-response-code>
            <avs-response-code-zip>U</avs-response-code-zip>
            <avs-response-code-address>U</avs-response-code-address>
            <avs-response-code-name>U</avs-response-code-name>
         </processing-info>
      </card-transaction>
    XML
  end

  def failed_void_response
    body = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <messages xmlns="http://ws.plimus.com">
        <message>
          <error-name>TRANSACTION_ID_REQUIRED</error-name>
          <code>20008</code>
          <description>Transaction operation cannot be completed due to missing transaction ID parameter.</description>
        </message>
      </messages>
    XML
    MockResponse.failed(body, 400)
  end

  def successful_verify_response
    MockResponse.succeeded <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <card-transaction xmlns="http://ws.plimus.com">
        <card-transaction-type>AUTH_ONLY</card-transaction-type>
        <transaction-id>1012082929</transaction-id>
        <recurring-transaction>ECOMMERCE</recurring-transaction>
        <soft-descriptor>Spreedly</soft-descriptor>
        <amount>0.00</amount>
        <currency>USD</currency>
        <card-holder-info>
          <first-name>Longbob</first-name>
          <last-name>Longsen</last-name>
          <country>CA</country>
          <state>ON</state>
          <city>Ottawa</city>
          <zip>K1C2N6</zip>
        </card-holder-info>
        <credit-card>
          <card-last-four-digits>9299</card-last-four-digits>
          <card-type>VISA</card-type>
          <card-sub-type>CREDIT</card-sub-type>
        </credit-card>
        <processing-info>
          <processing-status>success</processing-status>
          <cvv-response-code>ND</cvv-response-code>
          <avs-response-code-zip>U</avs-response-code-zip>
          <avs-response-code-address>U</avs-response-code-address>
          <avs-response-code-name>U</avs-response-code-name>
        </processing-info>
      </card-transaction>
    XML
  end

  def failed_verify_response
    body = <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <messages xmlns="http://ws.plimus.com">
        <message>
          <error-name>INCORRECT_INFORMATION</error-name>
          <code>14002</code>
          <description>Transaction failed  because of payment processing failure.: 430285 - Authorization has failed for this transaction. Please try again or contact your bank for assistance</description>
        </message>
      </messages>
    XML
    MockResponse.failed(body, 400)
  end

  def successful_store_response
    response = MockResponse.succeeded <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <vaulted-shopper xmlns="http://ws.plimus.com">
        <first-name>Longbob</first-name>
        <last-name>Longsen</last-name>
        <country>ca</country>
        <state>ON</state>
        <city>Ottawa</city>
        <zip>K1C2N6</zip>
        <shopper-currency>USD</shopper-currency>
        <payment-sources>
          <credit-card-info>
            <billing-contact-info>
              <first-name>Longbob</first-name>
              <last-name>Longsen</last-name>
              <city />
            </billing-contact-info>
            <credit-card>
              <card-last-four-digits>9299</card-last-four-digits>
              <card-type>VISA</card-type>
              <card-sub-type>CREDIT</card-sub-type>
            </credit-card>
            <processing-info>
              <cvv-response-code>ND</cvv-response-code>
              <avs-response-code-zip>U</avs-response-code-zip>
              <avs-response-code-address>U</avs-response-code-address>
              <avs-response-code-name>U</avs-response-code-name>
            </processing-info>
          </credit-card-info>
        </payment-sources>
      </vaulted-shopper>
    XML

    response.headers = { 'content-location' => 'https://sandbox.bluesnap.com/services/2/vaulted-shoppers/20936441' }
    response
  end

  def failed_store_response
    body =  <<-XML
      <?xml version="1.0" encoding="UTF-8"?>
      <messages xmlns="http://ws.plimus.com">
        <message>
          <error-name>INCORRECT_INFORMATION</error-name>
          <code>14002</code>
          <description>Transaction failed  because of payment processing failure.: 430285 - Authorization has failed for this transaction. Please try again or contact your bank for assistance</description>
        </message>
      </messages>
    XML
    MockResponse.failed(body, 400)
  end

  def forbidden_response
    MockResponse.new(403, '<xml>You are not authorized to perform this request due to inappropriate role permissions.</xml>')
  end

  def credentials_are_legit_response
    MockResponse.new(400, '<xml>Server Error</xml>')
  end

  def credentials_are_bogus_response
    MockResponse.new(401, %{<!DOCTYPE html><html lang="en"><head><title>HTTP Status 401 – Unauthorized</title><style type="text/css">h1 {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;font-size:22px;} h2 {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;font-size:16px;} h3 {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;font-size:14px;} body {font-family:Tahoma,Arial,sans-serif;color:black;background-color:white;} b {font-family:Tahoma,Arial,sans-serif;color:white;background-color:#525D76;} p {font-family:Tahoma,Arial,sans-serif;background:white;color:black;font-size:12px;} a {color:black;} a.name {color:black;} .line {height:1px;background-color:#525D76;border:none;}</style></head><body><h1>HTTP Status 401 – Unauthorized</h1><hr class="line" /><p><b>Type</b> Status Report</p><p><b>Message</b> Bad credentials</p><p><b>Description</b> The request has not been applied because it lacks valid authentication credentials for the target resource.</p><hr class="line" /><h3>Apache Tomcat Version X</h3></body></html>})
  end
end
