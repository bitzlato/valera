# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

require 'test_helper'

class BuyoutOrderCreatorTest < ActiveSupport::TestCase
  setup do
    @buyout_account = Account.find :binance
    @market = Market.find 'BTC_USDT-ERC20'
    @upstream_market = UpstreamMarket.find_by account: @buyout_account, market: @market
    @upstream_market.updated_at = Time.now
  end

  # Sold expensive. Create order to bought cheaper
  test 'successful create bid order for sold trade' do
    market_price = 100
    @upstream_market.bidPrice = market_price
    trade = trades(:ask)
    trade.update! price: market_price * 1.1
    buyout_order = BuyoutOrderCreator.new.call trade: trade, buyout_account: @buyout_account
    assert buyout_order.side?(:bid)
    assert buyout_order.price > market_price
    assert buyout_order.price < trade.price
    puts buyout_order.status
    puts buyout_order.ignore_message
    assert buyout_order.initial?
  end

  # Cancel buyout as price is outdated
  test 'outdated price' do
    market_price = 100
    @upstream_market.askPrice = market_price
    @upstream_market.updated_at = Time.now - 1.hour
    trade = trades(:bid)
    trade.update! price: market_price * 0.9
    buyout_order = BuyoutOrderCreator.new.call trade: trade, buyout_account: @buyout_account
    assert buyout_order.side?(:ask)
    assert buyout_order.price < market_price
    assert buyout_order.price > trade.price
    assert buyout_order.ignored?
  end

  # Bought cheap. Sold expensive
  test 'successful create ask order for bought trade' do
    market_price = 100
    @upstream_market.askPrice = market_price
    trade = trades(:bid)
    trade.update! price: market_price * 0.9
    buyout_order = BuyoutOrderCreator.new.call trade: trade, buyout_account: @buyout_account
    assert buyout_order.side?(:ask)
    assert buyout_order.price < market_price
    assert buyout_order.price > trade.price
    puts buyout_order.status
    puts buyout_order.ignore_message
    assert buyout_order.initial?
  end

  test 'ignore buyout of market price is higher than we bought' do
    market_price = 100
    @upstream_market.askPrice = market_price
    trade = trades(:bid)
    trade.update! price: market_price * 1.2
    buyout_order = BuyoutOrderCreator.new.call trade: trade, buyout_account: @buyout_account
    assert buyout_order.side?(:ask)
    assert buyout_order.ignored?
  end

  test 'ignore buyout of market price is lower than we sold' do
    market_price = 100
    @upstream_market.bidPrice = market_price
    trade = trades(:ask)
    trade.update! price: market_price * 0.9
    buyout_order = BuyoutOrderCreator.new.call trade: trade, buyout_account: @buyout_account
    assert buyout_order.side?(:bid)
    assert buyout_order.ignored?
  end
end
