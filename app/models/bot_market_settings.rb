# TODO rename UniverseSettings
#
class BotMarketSettings
  cattr_accessor :keys
  self.keys = %i[bid_place_threshold ask_place_threshold]
  include UniverseRedisObject
end
