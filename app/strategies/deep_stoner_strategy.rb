# frozen_string_literal: true

class DeepStonerStrategy < Strategy
  class Settings < StrategySettings
    attribute :base_min_volume, BigDecimal, default: 0.001
    validates :base_min_volume, presence: true, numericality: { greater_than: 0 }

    attribute :base_max_volume, BigDecimal, default: 0.002
    validates :base_max_volume, presence: true, numericality: { greater_than: 0 }

    LEVELS = 5
    LEVELS.times.each do |i|
      attribute "base_best_price_deviation_from_#{i}", Float, default: 10
      validates "base_best_price_deviation_from_#{i}", presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
      attribute "base_best_price_deviation_to_#{i}", Float, default: 10
      validates "base_best_price_deviation_to_#{i}", presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
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
        if best_price_for(side).nil?
          logger.debug("No upstream data (best price) for #{side}")
          next
        end
        settings.levels.times.map do |level|
          build_order(side, level)
        end
      end.flatten.compact
    )
  end

  def build_order(side, level)
    price_range = build_price_range side, level
    price = rand price_range
    logger.debug("Calculated price for #{side} level #{level} price_range=#{price_range} price=#{price}")

    volume = calculate_volume(side, level)
    comparer = lambda do |persisted_order|
      price_range.member?(persisted_order.price)
      # TODO Учитывать диапазон зазрешенного объёма или сбрасывать заявки после изменения объёма в настройках
      # иначе оно слишком часто прыгает
      # volume == persisted_order.origin_volume
    end

    super side, price, volume, comparer, level
  end

  def build_price_range(side, level)
    d = price_deviation_range side, level
    best_price = best_price_for side
    d.first.percent_of(best_price)..d.last.percent_of(best_price)
  end

  def price_deviation_range(side, level)
    deviation_from, deviation_to = [
      settings.send("base_best_price_deviation_from_#{level}"),
      settings.send("base_best_price_deviation_to_#{level}")
    ].sort

    case side
    when :ask
      (100.0.to_d + deviation_from)..(100.0.to_d + deviation_to)
    when :bid
      (100.to_d - deviation_to)..(100.to_d - deviation_from)
    else
      raise "WTF #{side}"
    end
  end

  def calculate_volume(side, level)
    liquidity_part = settings.send "base_liquidity_part_#{level}"

    return 0 if liquidity_part.zero?

    [
      [user_orders_volume(side) * liquidity_part / 100, settings.base_min_volume].max,
      settings.base_max_volume
    ].min
  end
end
