class UniverseLastData
  cattr_accessor :keys
  self.keys = %i[last_sell_order last_buy_order peatio_quote_balance]
  include UniverseRedisObject
end
