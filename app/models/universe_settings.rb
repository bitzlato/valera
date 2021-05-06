class UniverseSettings
  include RedisModel

  attribute :bid_place_threshold, BigDecimal
  attribute :ask_place_threshold, BigDecimal
  attribute :volume, BigDecimal

  validates :ask_place_threshold, presence: true, numericality: { greater_than: 0, less_than: 50 }
  validates :bid_place_threshold, presence: true, numericality: { less_than: 0, greater_than: -50 }
  validates :volume, presence: true, numericality: { greater_than: 0 }
end
