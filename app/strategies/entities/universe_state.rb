# frozen_string_literal: true

# New state for processor
class UniverseState
  include RedisModel

  # TODO fetch drainers from settings
  UPSTREAM_KEYS = (BinanceWebsocketDrainer::KEYS + PeatioWebsocketDrainer::KEYS).uniq
  UPSTREAMS = Settings.upstreams.keys
  UPSTREAMS.each do |upstream|
    UPSTREAM_KEYS.each do |key|
      attribute [upstream, key].join('_'), BigDecimal
    end
  end
  # attribute :peatio_base_balance, BigDecimal
  # attribute :peatio_quote_balance, BigDecimal
  #
  attribute :last_orders, Array[PersistedOrder]
end
