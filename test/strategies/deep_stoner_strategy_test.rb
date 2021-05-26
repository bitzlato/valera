# frozen_string_literal: true

require 'test_helper'

class DeepStonerStrategyTest < ActiveSupport::TestCase
  setup do
    @market = Market.all.first
    @upstream = Upstream.find(:peatio)
    upstream_market =
      @upstream.upstream_markets.find_by_market!(@market)
    upstream_market.usersAsksVolume = 123
    @account = Account.find(:peatio1)
    @account.instance_variable_set '@client', Peatio::Client::REST.new
    @strategy = DeepStonerStrategy.new(
      name: 'test',
      market: @market,
      account: @account
    )
  end

  test 'user_orders_volume' do
    ask_volume = @strategy.send :user_orders_volume, :ask
    assert_equal 123, ask_volume
  end
end
