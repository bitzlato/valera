class UniverseSettings
  include ActiveModel::Model
  include RedisModel

  attr_accessor :bid_place_threshold, :ask_place_threshold
end
