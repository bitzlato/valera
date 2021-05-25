# frozen_string_literal: true

require 'openssl'
# puts PeatioAPI::Client.new(endpoint: ENTPOINT).get_public('/api/v2/peatio/public/markets/tickers')
# puts client.get '/api/v2/peatio/orders', market: 'ethbtc'

module Peatio
  module Client
    class REST
      class Error < StandardError; end
      WrongResponse = Class.new Error
      Failure = Class.new Error

      # Map valera sides to clients sides
      SIDES_MAP = { bid: 'buy', ask: 'sell' }.freeze

      attr_reader :name

      def initialize(name: nil,
                     access_key: ENV['PEATIO_API_ACCESS_KEY'],
                     secret_key: ENV['PEATIO_API_SECRET_KEY'],
                     endpoint: ENV['PEATIO_ENDPOINT'],
                     prefix: '/api/v2/peatio')
        @access_key = access_key || raise('No access_key')
        @secret_key = secret_key || raise('No secret_key')
        @endpoint = endpoint || raise('No endpoint')
        @prefix = prefix || raise('No prefix')
        @name = name
      end

      def to_s
        name
      end

      def account_balances(currency = nil)
        if currency.present?
          get("/account/balances/#{currency}")
        else
          get('/account/balances')
        end
      end

      def markets
        get('/public/markets')
      end

      # market
      # ord_type = [market, limit] default is limit
      # price = require if ord_type == limit
      # side = [sell, buy] (OrderAsk, OrderBid)
      # volume
      def create_order(order)
        build_persisted_order(
          post('/market/orders', order.symbolize_keys.merge(side: SIDES_MAP.fetch(order.fetch(:side))))
        )
      end

      # optional :market,
      # optional :base_unit,
      # optional :quote_unit,
      # optional :state,
      # optional :limit,
      # optional :page,
      # optional :order_by,
      # optional :ord_type,
      # optional :type,
      # optional :time_from,
      # optional :time_to,
      def orders(params = {})
        get('/market/orders', params)
          .map { |data| build_persisted_order data }
      end

      def trades(params = {})
        get('/market/trades', params)
      end

      def cancel_order(order_id)
        post "/market/orders/#{order_id}/cancel"
      end

      # @param optional Hash with keys: market, side
      def cancel_orders(params = {})
        post '/market/orders/cancel', params
      end

      def order_book(market, params = {})
        get "/public/markets/#{market}/order-book", params
      end

      def market_depth(market)
        get "/public/markets/#{market}/depth"
      end

      def post(path, params = {})
        parse_response connection.post prefix + path, params.to_json
      end

      def get(path, params = {})
        parse_response connection.get prefix + path, params
      end

      private

      attr_reader :access_key, :secret_key, :endpoint, :prefix

      def connection
        nonce = (Time.now.to_f * 1000).to_i.to_s
        Faraday.new url: endpoint do |c|
          c.adapter Faraday.default_adapter
          # c.adapter :async_http
          c.headers = {
            'Content-Type' => 'application/json',
            'Accept' => 'application/json',
            'X-Auth-Apikey' => access_key,
            'X-Auth-Nonce' => nonce,
            'X-Auth-Signature' => OpenSSL::HMAC.hexdigest('SHA256', secret_key, nonce + access_key)
          }
          c.response :logger if ENV.true? 'FARADAY_LOGGER'
          if ENV.true? 'CURL_LOGGER'
            c.use Faraday::Response::Logger
            c.request :curl, logger, :warn
          end
        end
      end

      def parse_response(response)
        unless response.success?
          raise Failure,
                "Failed response status (#{response.status}) with body '#{response.body}' for #{name}"
        end
        return nil if response.body.empty?

        if response['content-type'] != 'application/json'
          raise WrongResponse,
                "Wrong content type (#{response['content-type']}) for #{name}"
        end

        results = JSON.parse response.body
        # attach headers, like 'per', 'per-page'
        results
      end

      # "id"=>1085518,
      # "uuid"=>"eefb9c4e-ca2a-464c-b22d-520176c30637",
      # "side"=>"sell",
      # "ord_type"=>"limit",
      # "price"=>"50377.1418",
      # "avg_price"=>"0.0",
      # "state"=>"pending",
      # "market"=>"btcusdt",
      # "market_type"=>"spot",
      # "created_at"=>"2021-05-13T08:15:30Z",
      # "updated_at"=>"2021-05-13T08:15:30Z",
      # "origin_volume"=>"0.0001",
      # "remaining_volume"=>"0.0001",
      # "executed_volume"=>"0.0",
      # "maker_fee"=>"0.0",
      # "taker_fee"=>"0.0",
      # "trades_count"=>0
      def build_persisted_order(raw)
        data = raw
               .symbolize_keys
               .slice(*PersistedOrder.attribute_set.map(&:name))
        data[:side] = SIDES_MAP.invert.fetch data.fetch(:side)
        data[:market_id] = Market.find_by!(peatio_symbol: raw.fetch('market')).id
        PersistedOrder.new data.merge(raw: raw)
      end

      def logger
        Logger.new($stdout)
      end
    end
  end
end
