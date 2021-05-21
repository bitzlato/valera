# frozen_string_literal: true

require 'test_helper'

class DeepStonerStrategyTest < ActiveSupport::TestCase
  setup do
    @market = Market.all.first
    @upstream = Upstream.find(:peatio)
    @account = Account.find(:peatio1)
    @account.instance_variable_set '@client', Peatio::Client::REST.new
    @account.active_orders = [
      PersistedOrder.new(id: 1, side: :ask, remaining_volume: 150, market_id: @market.id),
      PersistedOrder.new(id: 2, side: :ask, remaining_volume: 200, market_id: @market.id)
    ]
    @strategy = DeepStonerStrategy.new(
      name: 'test',
      market: @market,
      account: @account
    )
  end

  test 'user_orders_volume' do
    binding.pry
    askVolume = @strategy.send :user_orders_volume, :ask
    assert_equal 1, askVolume
  end
end
