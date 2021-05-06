# New state for processor
class UniverseState
  include RedisModel

  BinanceDrainer::KEYS.each do |key|
    attribute key, BigDecimal
  end
  attribute :peatio_base_balance, BigDecimal
  attribute :peatio_quote_balance, BigDecimal
  attribute :last_orders, Array
end
