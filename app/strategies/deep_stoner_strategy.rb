# frozen_string_literal: true

class DeepStonerStrategy < Universe
  class Settings < UniverseSettings
    attribute :base_min_volume, BigDecimal, default: 0.001
    validates :base_min_volume, presence: true, numericality: { greater_than: 0 }

    attribute :base_max_volume, BigDecimal, default: 0.002
    validates :base_max_volume, presence: true, numericality: { greater_than: 0 }

    attribute :base_day_limit, BigDecimal, default: 0.1
    validates :base_day_limit, presence: true, numericality: { greater_than: 0 }

    attribute :base_threshold, Float, default: 5
    validates :base_threshold, presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

    LEVELS = 5
    LEVELS.times.each do |i|
      attribute "base_best_price_deviation_#{i}", Float, default: 10
      validates "base_best_price_deviation_#{i}", presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
      attribute "base_liquidity_part_#{i}", Float, default: 10
      validates "base_liquidity_part_#{i}", presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
    end

    def levels
      LEVELS
    end
  end

  def self.description
    %(
    <p>Наполнятель стакана. Цель - иметь наполненный стакан.</p>
    <p>Делает заявки на объём <code>base_min_volume</code> базовой валюты по средней цене в стаканe, с разбросом от <code>base_min_threshold</code> до <code>base_max_threshold</code> %.</p>
    <p class="alert alert-warning">Пока в peatio не сформирован стакан цена берется из стакана binance</p>
    ).html_safe
  end

  private

  def build_orders
    Set.new(
      %i[ask bid].map do |side|
        settings.levels.times.map do |level|
          volume = calculate_volume(side, level)
          if volume.zero?
            logger.debug("Skip order for #{side} #{level}")
            nil
          else
            build_order(side, calculate_price(side, level), volume, level)
          end
        end
      end.flatten.compact
    )
  end

  def calculate_price(side, level)
    deviation = settings.send "base_best_price_deviation_#{level}"
    best_price = upstream_states[:binance].send "#{side}Price"

    threshold = settings.base_threshold * rand(100) / 100
    deviation += deviation * threshold / 100
    deviation = -deviation if side == :bid

    price = best_price + best_price * deviation / 100

    logger.debug("Calculated price for #{side} level #{level} threshold=#{threshold}% deviation=#{deviation}%, best_price=#{best_price} price=#{price}")

    price
  end

  def calculate_volume(_side, level)
    volume = settings.base_min_volume
    liquidity_part = settings.send "base_liquidity_part_#{level}"

    return 0 if liquidity_part.zero?

    # TODO: calculate volume from users_liquidity
    return volume if volume < settings.base_max_volume

    settings.base_max_volume
  end
end
