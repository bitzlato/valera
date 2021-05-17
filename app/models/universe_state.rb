# frozen_string_literal: true

# New state for processor
class UniverseState
  include RedisModel

  attribute :created_orders, Array[PersistedOrder]
  attribute :current_orders, Array[PersistedOrder]
end
