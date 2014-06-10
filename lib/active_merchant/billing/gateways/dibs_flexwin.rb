require 'digest'
require 'cgi'

module ActiveMerchant #:nodoc:
  module Billing #:nodoc:
    class DibsFlexWinGateway < Gateway
      self.test_url = self.live_url = 'https://payment.architrade.com/cgi-ssl/'
      self.homepage_url = 'http://www.dibs.dk'
      self.display_name = 'DIBS Payment Services'
      self.default_currency = 'EUR'
      self.supported_countries = ['DK', 'SE', 'NO']
      self.supported_cardtypes = [:visa, :master, :american_express, :diners_club, :jcb, :dankort, :maestro]

      DECLINED_CODES = ['0', '6', '11']

      INVALID_CARD_CODES = ['4', '9', '10']


      # @param [String] merchant_id  The DIBS merchant number (REQUIRED)
      # @param [String] md5_key_1    The DIBS MD5 key #1 (REQUIRED)
      # @param [String] md5_key_2    The DIBS MD5 key #2 (REQUIRED)
      # @param [Boolean] test        If the transaction should be run in test mode
      def initialize(options = {})
        requires!(options, :merchant_id, :md5_key_1, :md5_key_2)
        super
      end

      # Authorizes an amount on a user's card
      #
      # @param [Integer]    money       The number of cents (or yen in the case of JPY)
      # @param [CreditCard] creditcard  The user's credit card details
      # @param [Hash]       options     Please note that addresses are not sent to the API since it does not have fields for such
      # @return [MultiResponse]  Information about the authorization
      def authorize(money, creditcard, options = {})
        parameters = {}
        add_creditcard(parameters, creditcard)
        add_currency_code(parameters, money, options)
        add_invoice(parameters, options)
        add_customer_data(parameters, options)

        commit('auth.cgi', money, parameters)
      end

      # Captures the money from a previous authorization
      #
      # @param [Integer] money          The number of cents (or yen in the case of JPY)
      # @param [String]  authorization  The authorization attribute of the Response object from the authorize() request
      # @param [Hash]    options        Please note that addresses are not sent to the API since it does not have fields for such
      # @return [Response]  Information about the capture
      def capture(money, authorization, options = {})
        parameters = {transact: authorization}
        add_invoice(parameters, options)

        commit('capture.cgi', money, parameters)
      end

      # Peforms an instant purchase
      #
      # @param [Integer]    money       The number of cents (or yen in the case of JPY)
      # @param [CreditCard] creditcard  The user's credit card details
      # @param [Hash]       options     Please note that addresses are not sent to the API since it does not have fields for such
      # @return [MultiResponse]  Information about the purchase
      def purchase(money, creditcard, options = {})
        parameters = {}
        add_creditcard(parameters, creditcard)
        add_currency_code(parameters, money, options)
        add_invoice(parameters, options)
        add_customer_data(parameters, options)

        parameters[:capturenow] = 'yes'
        commit('auth.cgi', money, parameters)
      end

      # Cancels a transaction
      #
      # @param [String]  authorization  The authorization attribute of the Response object
      # @param [Hash]    options        Must contain the :order_id
      # @return [Response]  Information about the void - authorization will be the same as what was passed as the authorization
      def void(authorization, options = {})
        parameters = {transact: authorization}
        add_invoice(parameters, options)

        commit('cancel.cgi', nil, parameters)
      end

      # Refunds a part or the whole amount of a transaction
      #
      # @param [Integer] money           The number of cents (or yen in the case of JPY)
      # @param [String]  identification  The authorization attribute of the Response object
      # @param [Hash]    options         Must contain the :order_id, may contain the :currency
      # @return [Response]  Information about the refund - authorization will be the same as what was passed as the identification
      def refund(money, identification, options = {})
        parameters = {transact: authorization}
        add_currency_code(parameters, money, options)
        add_invoice(parameters, options)

        commit('refund.cgi', money, parameters)
      end

      private

      # The API does not have fields for customer info except for the ip
      #
      # @param [Hash] parameters  The data to be sent to the API
      # @param [Hash] options     The options the user passed to the class
      def add_customer_data(parameters, options)
        if options.has_key? :ip
          parameters[:ip] += options[:ip]
        end
      end

      # The API does not have fields to transmit addresses
      def add_address(parameters, creditcard, options)
      end

      # @param [Hash]    parameters  The data to be sent to the API
      # @param [Integer] money       The number of cents (or yen in the case of JPY)
      # @param [Hash]    options     The options the user passed to the class
      def add_currency_code(parameters, money, options)
        parameters[:currency] = options[:currency] || currency(money)
      end

      # The API does not have fields for description
      #
      # @param [Hash] parameters  The data to be sent to the API
      # @param [Hash] options     The options the user passed to the class
      def add_invoice(parameters, options)
        parameters[:orderid] = options[:order_id]
      end

      # Set the credit card details for the request. The API does not have
      # fields to transmit the card holder's name.
      #
      # @param [Hash]        parameters  The data to be sent to the API
      # @param [CreditCard]  creditcard  The CreditCard object for the user
      def add_creditcard(parameters, creditcard)
        parameters[:cardno]  = creditcard.number
        parameters[:expmon]  = sprintf("%.4i", creditcard.month)
        parameters[:expyear] = sprintf("%.2i", creditcard.year)[-2..-1]
        parameters[:cvc]     = creditcard.verification_value
      end

      # Runs a transaction on the API, returning the result
      #
      # @param [String]  endpoint    Which api endpoint to use
      # @param [Integer] money       The number of cents (or yen in the case of JPY)
      # @param [Hash]    parameters  Request information, using symbol keys
      # @return [Response]  The response from the transaction.
      def commit(endpoint, money, parameters)
        url = self.live_url + endpoint

        if money
          parameters[:amount]  = amount(money)
        end
        parameters[:merchant]  = @options[:merchant_id]
        parameters[:textreply] = 'yes'
        parameters[:fullreply] = 'yes'
        parameters[:md5key]    = generate_md5(endpoint, parameters)

        data = ssl_post(url, post_string)
        response_data = parse_response(data)

        message = message_from(response_data)

        Response.new(response_data[:status] == 'ACCEPTED', message, response_data,
          :test => test?,
          :authorization => response_data[:transact]
        )
      end

      # @param [Hash] response  The parsed response (symbol keys) from the API
      # @return [String]  The message
      def message_from(response)
        # TODO
      end

      # Generates an MD5 key for transactions
      #
      # @param [String] endpoint    The API endpoint being used
      # @param [Hash]   parameters  The request parameters (symbol keys)
      # @return [String]  The MD5 key for the request
      def generate_md5(endpoint, parameters)
        fields = [:merchant, :orderid]

        if endpoint == 'auth.cgi'
          fields.merge!([:currency, :amount])

        elsif endpoint = 'cancel.cgi'
          fields << :transact

        elsif ['capture.cgi', 'refund.cgi'].include?(endpoint)
          fields.merge!([:transact, :amount])
        end

        pairs = []

        pairs = fields.map do |field|
          "#{field.to_s}=#{CGI::escape(parameters[field].to_s)}"
        end

        data = pairs.join('&')

        first_hash = Digest::MD5.hexdigest(@options[:md5_key_1] + data)
        Digest::MD5.hexdigest(@options[:md5_key_2] + first_hash)
      end

      # Parses the raw response data into a Hash
      #
      # @param [String] data  The url-encoded response from the API
      # @return [Hash]  The parsed data, using symbols for keys
      def parse_response(data)
        response = {}
        CGI.parse(data).each do |key, value|
          if value.length == 1
            value = value[0]
          end
          response[key.to_sym] = value
        end
        response
      end
    end
  end
end

