class BotMarketSettings
  cattr_accessor :keys
  self.keys = %i[bit_place_threshold ask_place_threshold]
  include UniverseRedisObject
end
