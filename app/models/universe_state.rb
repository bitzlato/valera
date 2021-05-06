# New state for processor
class UniverseState
  include ActiveModel::Model
  include RedisModel

  attr_accessor(*BinanceDrainer::KEYS)

  attr_accessor :peatio_quote_balance, :peatio_base_balance
  attr_accessor :last_orders
end
