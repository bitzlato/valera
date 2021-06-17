# frozen_string_literal: true

require 'test_helper'

class BuyoutOrderCreatorTest < ActiveSupport::TestCase
  test 'create buyout order from sell trade' do
    trade = trades(:sell)
    buyout_account = Minitest::Mock.new
    buyout_account.expect(:id, :binance)

    buyout_order = BuyoutOrderCreator.call trade, buyout_account
    assert buyout_order.is_a?(BuyoutOrder)
  end
end
