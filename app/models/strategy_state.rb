# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

# New state for processor
class StrategyState
  include RedisModel
  include StrategyActivation

  attribute :created_orders, Array[PersistedOrder]
  attribute :maker_pid, Integer

  attribute :best_ask_price, BigDecimal
  attribute :best_bid_price, BigDecimal

  attribute :last_error_message, String

  attribute :acted_at, Time
  attribute :last_errors, Array[String]
end
