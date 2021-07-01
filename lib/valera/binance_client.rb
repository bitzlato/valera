# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

require_relative 'base_client'

module Valera
  class BinanceClient < BaseClient
    SIDES_MAP = { bid: 'buy', ask: 'sell' }.freeze

    attr_reader :api_key, :secret_key, :client

    def initialize(name:, api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
      @name = name
      @client = Binance::Client::REST.new api_key: api_key, secret_key: secret_key
      super()
    end

    def account_balances
      raise_on_response_errors(
        client
        .account_info
        .fetch('balances')
      )
        .each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |r, a|
        a[r.fetch('asset')] = { available: r['free'], locked: r['locked'] }
      end
    end

    def open_orders
      # https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md#current-open-orders-user_data
      raise_on_response_errors client.open_orders
    end

    def my_trades(markets)
      # https://github.com/binance/binance-spot-api-docs/blob/master/rest-api.md#account-trade-list-user_data
      markets.map do |market|
        raise_on_response_errors client.my_trades(symbol: market.binance_symbol)
      end.flatten
    end

    # rubocop:disable Metrics/ParameterLists
    #
    # @params:
    # market
    # ord_type = [market, limit] default is limit
    # price = require if ord_type == limit
    # side = [sell, buy] (OrderAsk, OrderBid)
    # volume
    # time_in_force typicaly is IOC
    def create_order(market:, price:, side:, volume:, time_in_force:, ord_type: :limit)
      order = {
        symbol: market.binance_symbol,
        side: SIDES_MAP.fetch(side),
        type: ord_type,
        price: price,
        quantity: volume,
        timeInForce: time_in_force
      }
      build_persisted_order(
        raise_on_response_errors(client.create_order!(order))
      )
    end
    # rubocop:enable Metrics/ParameterLists

    def endpoint
      'binance'
    end

    private

    def raise_on_response_errors(response)
      raise OrderCreationError, response if response.key? 'code'

      response
    end

    #=> {"symbol"=>"BTCUSDT",
    # "orderId"=>6701103026,
    # "orderListId"=>-1,
    # "clientOrderId"=>"593sI8NwGFu55uT0uLXypq",
    # "transactTime"=>1625128651680,
    # "price"=>"33360.00000000",
    # "origQty"=>"0.00100000",
    # "executedQty"=>"0.00100000",
    # "cummulativeQuoteQty"=>"33.38505000",
    # "status"=>"FILLED",
    # "timeInForce"=>"IOC",
    # "type"=>"LIMIT",
    # "side"=>"SELL",
    # "fills"=>[{"price"=>"33385.05000000", "qty"=>"0.00100000",
    #            "commission"=>"0.03338505", "commissionAsset"=>"USDT", "tradeId"=>940968667}]}
    def build_persisted_order(raw_order)
      raise_on_response_errors

      PersistedOrder.new(
        raw: raw_order,
        market: Market.find_by(binance_symbol: raw_order['symbol']),
        side: SIDES_MAP.invert.fetch(raw_order.fetch('side').downcase),
        id: raw_order['orderId'],
        price: raw_order['price'],
        executed_volume: raw_order['executedQty'],
        origin_volume: raw_order['origQty'],
        state: raw_order['status'],
        trades_count: raw_order['fills'].count,
        ord_type: raw_order['type'],
        created_at: Time.at(raw_order['transactTime'] / 1000)
      ).freeze
    end
  end
end
