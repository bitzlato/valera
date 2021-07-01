# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

require_relative 'base_client'

module Valera
  class BinanceClient < BaseClient
    attr_reader :api_key, :secret_key, :client

    def initialize(name:, api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
      @name = name
      @client = Binance::Client::REST.new api_key: api_key, secret_key: secret_key
      super()
    end

    def account_balances
      client
        .account_info
        .fetch('balances')
        .each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |r, a|
        a[r.fetch('asset')] = { available: r['free'], locked: r['locked'] }
      end
    end

    def create_order
      raise 'not implemented'
    end

    def endpoint
      'binance'
    end
  end
end
