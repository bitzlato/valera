# frozen_string_literal: true

require 'test_helper'

class DeepStonerStrategyTest < ActiveSupport::TestCase
  setup do
    @market = Market.all.first
    @upstream = Upstream.find(:peatio)

    upstream_market = @upstream.upstream_markets.find_by_market!(@market)
    upstream_market.usersAsksVolume = 123

    @account = Account.find(:peatio1)
    @account.instance_variable_set '@client',
                                   Valera::PeatioClient.new(access_key: 'access_key', secret_key: 'secret_key')
    @source_account = Account.find(:binance)
    @source_account.instance_variable_set '@client',
                                          Valera::BinanceClient.new(name: 'name', api_key: 'api_key',
                                                                    secret_key: 'secret_key')

    @source_upstream_market = @source_account.upstream_markets.find_by_market!(@market)
    @source_upstream_market.askPrice = 11_000
    @source_upstream_market.bidPrice = 9000

    @strategy = DeepStonerStrategy.new(
      name: 'test',
      market: @market,
      account: @account,
      buyout_account: @source_account,
      source_account: @source_account
    )
  end

  test 'users_orders_volume' do
    ask_volume = @strategy.send :users_orders_volume, :ask
    assert_equal 123, ask_volume
  end

  test 'update_orders!' do
    assert @strategy.send :update_orders!
  end
end
