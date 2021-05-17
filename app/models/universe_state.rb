# frozen_string_literal: true

# New state for processor
class UniverseState
  include RedisModel

  # attribute :last_orders, Array[PersistedOrder]
  attribute :created_orders, Array[PersistedOrder]
end
