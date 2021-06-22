# frozen_string_literal: true

require 'test_helper'

class BuyoutOrderCreatorTest < ActiveSupport::TestCase
  setup do
    @buyout_account = Account.find(:binance)
    @market = Market.find('BTC_USDT')
    @upstream_market = UpstreamMarket.find_by(account: @buyout_account, market: @market)
    # @upstream_market.bidPrice = 90
  end

  test 'ignore buyout order if sell price is lower then traded price' do
    trade = trades(:ask)
    @upstream_market.askPrice = trade.price - 10
    buyout_order = BuyoutOrderCreator.call trade: trade, buyout_account: @buyout_account
    assert buyout_order.side?(:bid)
    assert buyout_order.ignored?
  end

  test 'success create bid buyout order' do
    trade = trades(:ask)
    @upstream_market.askPrice = trade.price + 10
    buyout_order = BuyoutOrderCreator.call trade: trade, buyout_account: @buyout_account
    assert buyout_order.side?(:bid)
    assert buyout_order.initial?
  end

  test 'ignore buyout order if buy price is higher then traded price' do
    trade = trades(:bid)
    @upstream_market.bidPrice = trade.price + 10
    buyout_order = BuyoutOrderCreator.call trade: trade, buyout_account: @buyout_account
    assert buyout_order.side?(:ask)
    assert buyout_order.ignored?
  end

  test 'success ask buyout order' do
    trade = trades(:bid)
    @upstream_market.bidPrice = trade.price - 10
    buyout_order = BuyoutOrderCreator.call trade: trade, buyout_account: @buyout_account
    assert buyout_order.side?(:ask)
    assert buyout_order.initial?
  end
end
