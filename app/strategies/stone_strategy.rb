class StoneStrategy < Universe
  class Settings < UniverseSettings
    attribute :ask_place_threshold, BigDecimal, default: 5
    attribute :ask_volume, BigDecimal, default: 0.001
    attribute :bid_place_threshold, BigDecimal, default: -5
    attribute :bid_volume, BigDecimal, default: 0.001

    validates :ask_place_threshold, presence: true, numericality: { greater_than: 0, less_than: 50 }
    validates :ask_volume, presence: true, numericality: { greater_than: 0 }
    validates :bid_place_threshold, presence: true, numericality: { less_than: 0, greater_than: -50 }
    validates :bid_volume, presence: true, numericality: { greater_than: 0 }
  end
  def self.description
    'desc'
  end

  private

  def calculate_price(side)
    sidePrice = state.send "#{side}Price"
    sidePrice + sidePrice * settings.send("#{side}_place_threshold")/100
  end

  def calculate_volume(side)
    settings.send side.to_s+'_volume'
  end
end
