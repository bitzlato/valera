# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

require 'test_helper'

class PeatioRestDrainerTest < ActiveSupport::TestCase
  setup do
    account = Account.all.first
    @drainer = PeatioRestDrainer.new id: 1, market: Market.all.first, account: account
  end

  test 'fetch_market_depth' do
    assert_equal @drainer.send(:fetch_market_depth), { 'asksVolume' => 0.13e-2, 'bidsVolume' => 0.0 }
  end
end
