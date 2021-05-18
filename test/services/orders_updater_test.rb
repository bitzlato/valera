# frozen_string_literal: true

require 'test_helper'

class OrdersUpdaterTest < ActiveSupport::TestCase
  setup do
    @market = Market.all.first
    @client = PeatioClient.new
    @updater = OrdersUpdater.new(client: @client, market: @market, name: 'test')
  end
  test 'update!' do
    orders = Set[
      Order.new(side: :ask, volume: 2, price: 1)
    ]
    @updater.update! orders
    assert true
  end
end
