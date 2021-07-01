# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

require 'test_helper'

class PeatioClientTest < ActiveSupport::TestCase
  def setup
    @client = Valera::PeatioClient.new(name: :name,
                                       endpoint: 'http://peatio',
                                       access_key: 'access_key',
                                       secret_key: 'secret_key')
  end

  def test_inffuccient_error
    stub_request(:post, 'http://peatio/api/v2/peatio/market/orders')
      .to_return(status: 422,
                 body: { errors: ['market.account.insufficient_balance'] }.to_json,
                 headers: { 'Content-Type' => 'application/json' })
    assert_raises Valera::BaseClient::InsufficientBalance do
      @client.create_order side: :ask, price: 1, volume: 2, market: Market.all.first
    end
  end
end
