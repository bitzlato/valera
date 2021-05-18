# frozen_string_literal: true

# New state for processor
class StrategyState
  include RedisModel

  attribute :created_orders, Array[PersistedOrder]
  attribute :current_orders, Array[PersistedOrder]
end
