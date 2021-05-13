# frozen_string_literal: true

# New state for processor
class UniverseState
  UPSTREAMS = %i[binance peatio].freeze

  include RedisModel

  UPSTREAMS.each do |upstream|
    BinanceDrainer::KEYS.each do |key|
      attribute [upstream, key].join('_'), BigDecimal
    end
  end
  # attribute :peatio_base_balance, BigDecimal
  # attribute :peatio_quote_balance, BigDecimal
  #
  attribute :last_orders, Array
end
