# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
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

    attribute 'base_bid_total_volume', Float, default: 0.01
    validates 'base_bid_total_volume', presence: true, numericality: { greater_than_or_equal_to: 0 }

    attribute 'base_ask_total_volume', Float, default: 0.01
    validates 'base_ask_total_volume', presence: true, numericality: { greater_than_or_equal_to: 0 }

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

  # rubocop:disable Metrics/ParameterLists
  def initialize(name:, market:, account:, source_account:, buyout_account:, default_settings: {}, comment: nil)
    @buyout_account = buyout_account
    super(
      name: name,
      market: market,
      account: account,
      source_account: source_account,
      default_settings: default_settings,
      comment: comment
    )
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

  def update_orders!
    orders_to_create = []
    orders_to_cancel = []

    account.update_active_orders!

    %i[ask bid].map do |side|
      prepare_orders_by_side(side, orders_to_cancel, orders_to_create)
    end

    updater.cancel_orders! orders_to_cancel if orders_to_cancel.any?
    updater.create_orders! orders_to_create if orders_to_create.any?

    state.update_attributes!(
      best_ask_price: best_price_for(:ask),
      best_bid_price: best_price_for(:bid),
      created_orders: orders_to_create.to_a,
      last_error_message: updater.errors.join('; ')
    )
  rescue StandardError => e
    report_exception(e) unless e.is_a? Valera::BaseClient::InsufficientBalance
    logger.error(e)
    state.update_attributes!(
      best_ask_price: best_price_for(:ask),
      best_bid_price: best_price_for(:bid),
      created_orders: [],
      last_error_message: e.message
    )
  end

  # rubpcop:disable Metrics/CyclomaticComplexity
  # rubocop:disable Metrics/PerceivedComplexity
  def prepare_orders_by_side(side, orders_to_cancel, orders_to_create)
    leveled_orders = settings.levels.times.each_with_object({}) { |a, o| o[a] = [] }

    account.active_orders.filter { |o| o.market == market && o.side?(side) }.each do |persisted_order|
      level = find_level_of_order persisted_order
      if level.nil?
        orders_to_cancel << persisted_order
      else
        leveled_orders[level] << persisted_order
      end
    end

    settings.levels.times.map do |level|
      target_orders_volume = calculate_target_orders_volume side, level
      logger.debug("target_orders_volume(level:#{level},side:#{side})=#{target_orders_volume}")

      persisted_orders = leveled_orders[level]

      orders_to_cancel << persisted_orders.pop while persisted_orders.sum(&:remaining_volume) > target_orders_volume

      persisted_volume = persisted_orders.sum(&:remaining_volume)
      new_orders = []
      while persisted_volume + new_orders.sum(&:volume) < target_orders_volume && target_orders_volume - (persisted_volume + new_orders.sum(&:volume)) > settings.base_min_volume
        order = build_order(side, level, target_orders_volume - new_orders.sum(&:volume) - persisted_volume)
        new_orders << order unless order.nil?
      end

      orders_to_create.push(*new_orders)

      if new_orders.sum(&:volume) + persisted_orders.sum(&:remaining_volume) - orders_to_create.sum(&:volume) > target_orders_volume
        raise "Total orders sum (#{new_orders.sum(&:volume)} + #{persisted_orders.sum(&:remaining_volume)} - #{orders_to_create.sum(&:volume)}) larget then target #{target_orders_volume}"
      end
    end
  end
  # rubpcop:enable Metrics/CyclomaticComplexity
  # rubocop:enable Metrics/PerceivedComplexity

  def find_level_of_order(persisted_order)
    volume_range = settings.base_min_volume.to_f..settings.base_max_volume.to_f
    settings.levels.times.find do |level|
      build_price_range(persisted_order.side, level).member?(persisted_order.price) && volume_range.member?(persisted_order.remaining_volume)
    end
  end

  def build_order(side, level, max_volume)
    volume_range = settings.base_min_volume.to_f..[settings.base_max_volume, max_volume].min.to_f
    price_range = build_price_range side, level
    comparer = lambda do |persisted_order|
      !settings.base_mad_mode_enable? && \
        price_range.member?(persisted_order.price) && \
        volume_range.member?(persisted_order.remaining_volume)
    end
    price = rand price_range
    volume = rand volume_range
    logger.debug("Calculated price for #{side} level #{level} price_range=#{price_range} price=#{price} volume=#{volume}")
    super side, price, volume, comparer, level
  end

  def build_price_range(side, level)
    d = price_deviation_range side, level
    best_price = best_price_for side
    raise "no best price for #{side}" if best_price.to_d.zero?

    d.first.percent_of(best_price)..d.last.percent_of(best_price)
  end

  def price_deviation_range(side, level)
    level -= level / LEVELS_DECADE * LEVELS_DECADE
    deviation_from, deviation_to = [
      settings.send("base_best_price_deviation_from_#{level}"),
      settings.send("base_best_price_deviation_to_#{level}")
    ].sort

    case side.to_sym
    when :ask
      (100.0.to_d + deviation_from)..(100.0.to_d + deviation_to)
    when :bid
      (100.to_d - deviation_to)..(100.to_d - deviation_from)
    else
      raise "WTF #{side}"
    end
  end

  def calculate_target_orders_volume(side, level)
    level -= level / LEVELS_DECADE * LEVELS_DECADE
    liquidity_part = settings.send "base_liquidity_part_#{level}"
    if settings.base_enable_order_by_liquidity
      liquidity_part.percent_of users_orders_volume(side)
    else
      liquidity_part.percent_of settings.send("base_#{side}_total_volume")
    end
  end
end
# rubocop:enable Metrics/ClassLength
