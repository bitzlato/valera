class UniverseLastData
  cattr_accessor :keys
  self.keys = %i[last_sell_order last_buy_order peatio_quote_balance peatio_base_balance kline_high kline_low]
  include UniverseRedisObject
end
