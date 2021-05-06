class UniverseSettings
  include RedisModel

  attribute :bid_place_threshold, BigDecimal
  attribute :bid_volume, BigDecimal
  attribute :ask_place_threshold, BigDecimal
  attribute :ask_volume, BigDecimal

  validates :ask_place_threshold, presence: true, numericality: { greater_than: 0, less_than: 50 }
  validates :ask_volume, presence: true, numericality: { greater_than: 0 }
  validates :bid_place_threshold, presence: true, numericality: { less_than: 0, greater_than: -50 }
  validates :bid_volume, presence: true, numericality: { greater_than: 0 }

  def self.scope_attributes(scope)
    attribute_set.map(&:name).select { |k| k.to_s.starts_with? scope.to_s + '_' }
  end
end
