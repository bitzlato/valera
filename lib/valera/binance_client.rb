# frozen_string_literal: true

require_relative 'base_client'

module Valera
  class BinanceClient < BaseClient
    def create_order; end

    def endpoint
      'binance'
    end
  end
end
