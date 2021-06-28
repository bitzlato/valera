# frozen_string_literal: true

require_relative 'base_client'

module Valera
  class BinanceClient < BaseClient
    def initialize(name:, api_key:, secret_key:); end

    def create_order; end

    def endpoint
      'binance'
    end
  end
end
