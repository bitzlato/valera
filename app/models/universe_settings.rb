class UniverseSettings
  include RedisModel

  attribute :bid_place_threshold, BigDecimal
  attribute :ask_place_threshold, BigDecimal
  attribute :volume, BigDecimal
end
