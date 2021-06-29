# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class OrderBookStrategy < Strategy
  class Settings < StrategySettings
    MAX_THRESHOLD = 5
    attribute :base_volume, BigDecimal, default: 0.001
    attribute :base_depth, Integer, default: 5
    attribute :base_max_threshold, BigDecimal, default: 3
    attribute :base_min_threshold, BigDecimal, default: 1

    validates :base_volume, presence: true, numericality: { greater_than: 0 }
    validates :base_depth, presence: true,
                           numericality: { greater_than: 0, less_than: 20, only_integer: true }
    validates :base_max_threshold, presence: true,
                                   numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: MAX_THRESHOLD }
    validates :base_min_threshold, presence: true,
                                   numericality: { greater_than_or_equal_to: 1, less_than_or_equal_to: MAX_THRESHOLD }
  end

  class State < StrategyState
    def to_hash
      super.merge avgPrice: avgPrice
    end

    def avgPrice
      return if askPrice.nil? || bidPrice.nil?

      (askPrice + bidPrice) / 2
    end
  end

  def self.description
    %(
    <p>Наполнятель стакана. Цель - иметь наполненный стакан.</p>
    <p>Делает заявки на объём <code>base_volume</code> базовой валюты по средней цене в стаканe, с разбросом от <code>base_min_threshold</code> до <code>base_max_threshold</code> %.</p>
    <p class="alert alert-warning">Пока в peatio не сформирован стакан цена берется из стакана binance</p>
    ).html_safe
  end

  private

  def build_orders
    Set.new(
      %i[ask bid].map do |side|
        settings.base_depth.times.map do
          build_order(side, calculate_price(side), calculate_volume(side))
        end
      end.flatten.compact
    )
  end

  def calculate_price(side)
    threshold = settings.base_min_threshold + (settings.base_max_threshold - settings.base_min_threshold) * rand(100) / 100
    threshold = -threshold if side == :bid
    logger.debug "#{side} base_max_threshold = #{settings.base_max_threshold}, base_min_threshold = #{settings.base_min_threshold}, threshold = #{threshold}"
    state.avgPrice + state.avgPrice * threshold / 100
    # TODO: Брать среднюю цену стакана из peatio
  end

  def calculate_volume(_side)
    settings.base_volume
  end
end
