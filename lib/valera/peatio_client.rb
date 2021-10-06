# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

require 'openssl'
require_relative 'base_client'

# Usage example:
#
# puts PeatioAPI::Client.new(endpoint: ENTPOINT).get_public('/api/v2/peatio/public/markets/tickers')
# puts client.get '/api/v2/peatio/orders', market: 'ethbtc'

module Valera
  # rubocop:disable Metrics/ClassLength
  class PeatioClient < BaseClient
    # Map valera sides to clients sides
    SIDES_MAP = { bid: 'buy', ask: 'sell' }.freeze

    attr_reader :prefix

    def initialize(name:,
                   access_key: ENV['PEATIO_API_ACCESS_KEY'],
                   secret_key: ENV['PEATIO_API_SECRET_KEY'],
                   endpoint: ENV['PEATIO_ENDPOINT'],
                   prefix: '/api/v2/peatio')
      @access_key = access_key || raise('No access_key')
      @secret_key = secret_key || raise('No secret_key')
      @endpoint = endpoint || raise('No endpoint')
      @prefix = prefix || raise('No prefix')
      @name = name
      super()
    end

    def account_balances(currency = nil)
      if currency.present?
        get("/account/balances/#{currency}")
      else
        get('/account/balances').each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |r, a|
          a[r['currency'].upcase] = { available: r['balance'], locked: r['locked'] }
        end
      end
    end

    def markets
      get('/public/markets')
    end

    # @params:
    # market
    # ord_type = [market, limit] default is limit
    # price = require if ord_type == limit
    # side = [sell, buy] (OrderAsk, OrderBid)
    # volume
    # time_in_force is not used
    #
    # rubocop:disable Lint/UnusedMethodArgument
    # rubocop:disable Metrics/ParameterLists
    def create_order(market:, price:, side:, volume:, ord_type: :limit, time_in_force: nil)
      order = {
        market: market.peatio_symbol,
        side: SIDES_MAP.fetch(side),
        ord_type: ord_type,
        price: price,
        volume: volume
      }
      build_persisted_order(
        post('/market/orders', order),
        skip_unknown_market: false
      )
    rescue Valera::BaseClient::Failure => e
      report_exception e, true, order: order unless e.is_a? InsufficientBalance
      raise e
    end
    # rubocop:enable Metrics/ParameterLists
    # rubocop:enable Lint/UnusedMethodArgument

    def open_orders
      orders(state: :wait)
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
        .compact
    end

    # @return  [
    # "id", "price", "amount", "total", "fee_currency", "fee", "fee_amount",
    # "market", "market_type", "created_at", "taker_type", "side", "order_id", "market_symbol"
    # ]
    def my_trades(_markets)
      trades.map do |trade|
        trade['market_symbol'] = trade['market']
        trade['market'] = Market.find_by(peatio_symbol: trade['market'])
        trade
      end
    end

    def trades(params = {})
      get('/market/trades', params).map do |trade|
        trade.merge('side' => SIDES_MAP.invert.fetch(trade['side']))
      end
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

    attr_reader :access_key, :secret_key

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
      if response['content-type'] != 'application/json'
        raise WrongResponse,
              "Wrong content type (#{response['content-type']}) for #{name} with body #{response.body.truncate(100)}"
      end

      data = response.body.empty? ? nil : JSON.parse(response.body)
      return data if response.success?

      if response.status.to_i == 422 && data['errors'].include?('market.account.insufficient_balance')
        raise InsufficientBalance
      end

      if response.status.to_i == 422 && data['errors'].include?('order.invalid_volume_or_price"')
        raise InvaildVolumeOrPrice
      end

      raise Failure,
            "Failed response status (#{response.status}) with body '#{response.body}' for #{name}"

      # attach headers, like 'per', 'per-page'
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
    def build_persisted_order(raw, skip_unknown_market: true)
      data = raw
             .symbolize_keys
             .slice(*PersistedOrder.attribute_set.map(&:name))
      data[:side] = SIDES_MAP.invert.fetch data.fetch(:side)
      market = Market.find_by(peatio_symbol: raw.fetch('market'))
      if market.present?
        data[:market_id] = market.id
        PersistedOrder.new(data.merge(raw: raw)).freeze
      elsif skip_unknown_market
        logger.warn "Unknown market #{raw.fetch('market')}. Ignore order #{data}"
        nil
      else
        raise Error, "Unknown market #{raw.fetch('market')}"
      end
    end

    def logger
      Logger.new($stdout)
    end
  end
  # rubocop:enable Metrics/ClassLength
end
