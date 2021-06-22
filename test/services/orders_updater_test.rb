# frozen_string_literal: true

require 'test_helper'

class OrdersUpdaterTest < ActiveSupport::TestCase
  setup do
    market = Market.all.first
    account = Account.all.first
    @updater = OrdersUpdater.new(account: account, market: market, name: 'test')
  end

  test 'update!' do
    orders = Set[
      Order.new(side: :ask, volume: 2, price: 1)
    ]
    assert @updater.update! orders
  end
end
