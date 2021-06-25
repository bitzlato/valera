# frozen_string_literal: true

class DeepStonerStrategy < Strategy
  LEVELS_MULT = ENV.fetch('LEVELS_MULT', 1).to_i
  LEVELS_DECADE = ENV.fetch('LEVELS_DECADE', 10).to_i

  attr_reader :buyout_account

  class Settings < StrategySettings
    attribute :base_min_volume, BigDecimal, default: 0.001
    validates :base_min_volume, presence: true, numericality: { greater_than: 0 }

    attribute :base_max_volume, BigDecimal, default: 0.002
    validates :base_max_volume, presence: true, numericality: { greater_than: 0 }

    attribute :buyout_enable, Boolean, default: false

    attribute :buyout_ask_percentage, BigDecimal, default: 0.1
    validates :buyout_ask_percentage, presence: true, numericality: { greater_than_or_equal_to: 0.1, lower_than: 2 }

    attribute :buyout_bid_percentage, BigDecimal, default: 0.1
    validates :buyout_bid_percentage, presence: true, numericality: { greater_than_or_equal_to: 0.1, lower_than: 2 }

    attribute :base_mad_mode_enable, Boolean, default: false

    attribute :base_enable_order_by_liquidity, Boolean, default: false

    LEVELS = 5
    LEVELS.times.each do |i|
      attribute "base_best_price_deviation_from_#{i}", Float, default: 10
      validates "base_best_price_deviation_from_#{i}", presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
      attribute "base_best_price_deviation_to_#{i}", Float, default: 10
      validates "base_best_price_deviation_to_#{i}", presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }
      attribute "base_liquidity_part_#{i}", Float, default: 10
      validates "base_liquidity_part_#{i}", presence: true, numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 100 }

      attribute "base_total_volume_#{i}", Float, default: 1
      validates "base_total_volume_#{i}", presence: true, numericality: { greater_than: 0 }
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

  # rubocop:disable Metrics/ParameterLists
  def initialize(name:, market:, account:, buyout_account:, default_settings: {}, comment: nil)
    @buyout_account = buyout_account
    super name: name, market: market, account: account, default_settings: default_settings, comment: comment
  end
  # rubocop:enable Metrics/ParameterLists

  def trade_created(trade)
    if settings.buyout_enable?
      BuyoutOrderCreator
        .call(trade: trade,
              buyout_account: buyout_account,
              ask_percentage: settings.buyout_ask_percentage,
              bid_percentage: settings.buyout_bid_percentage)
    end
    super
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
          LEVELS_MULT.times.map do |index|
            build_order(side, level + index * LEVELS_DECADE)
          end
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
      !settings.base_mad_mode_enable? && price_range.member?(persisted_order.price)
    end

    super side, price, volume, comparer, level
  end

  def build_price_range(side, level)
    d = price_deviation_range side, level
    best_price = best_price_for side
    d.first.percent_of(best_price)..d.last.percent_of(best_price)
  end

  def price_deviation_range(side, level)
    level -= level / LEVELS_DECADE * LEVELS_DECADE
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
    level -= level / LEVELS_DECADE * LEVELS_DECADE
    liquidity_part = settings.send "base_liquidity_part_#{level}"

    return 0 if liquidity_part.zero?

    [
      [user_orders_volume(side) * liquidity_part / 100, settings.base_min_volume].max,
      settings.base_max_volume
    ].min
  end
end
