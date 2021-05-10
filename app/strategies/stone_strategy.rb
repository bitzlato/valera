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
    %{
    <p>Камни.</p>
    <p>Создаёт заявки с существенным сдвигом (<em>bid_place_threshold</em>, <em>ask_place_threshold</em>) от последней цены покупки/продажи на бирже-источнике (binance) размером <em>ask_volume</em>, <em>bid_volume</em>.</p>
    }.html_safe
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
