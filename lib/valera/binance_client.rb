# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

require_relative 'base_client'

module Valera
  class BinanceClient < BaseClient
    attr_reader :api_key, :secret_key

    def initialize(name:, api_key:, secret_key:)
      @api_key = api_key
      @secret_key = secret_key
      @name = name
      super()
    end

    def create_order
      raise 'not implemented'
    end

    def endpoint
      'binance'
    end
  end
end
