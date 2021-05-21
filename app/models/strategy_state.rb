# frozen_string_literal: true

# New state for processor
class StrategyState
  include RedisModel
  include StrategyActivation

  attribute :created_orders, Array[PersistedOrder]
  attribute :maker_pid, Integer
end
