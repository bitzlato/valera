# frozen_string_literal: true

# Smartly updates private order book for market/account and logs changes.
#
class OrdersUpdater
  include AutoLogger

  INFLUX_TABLE = 'processor'

  # If volume*price of order is changed on less then this percentage the order will not be changed
  AVAILABLE_DIVERGENCE = 0.01
  SIDES_MAP = { bid: :buy, ask: :sell }.freeze

  attr_reader :peatio_client, :market, :logger, :name

  def initialize(peatio_client:, market:, name:)
    @market = market || raise('No market')
    @peatio_client = peatio_client || raise('No peatio client')
    @logger = ActiveSupport::TaggedLogging.new(_build_auto_logger)
                                          .tagged([market, peatio_client.name].join(' '))
    @name = name
  end

  # Updates orders on market. Cancel redundant orders and create new if necessary
  # @param Set[Order]
  def update!(orders)
    raise 'Must be a Set' unless orders.is_a? Set

    logger.info "Update with #{orders.to_a.join(',')}"
    Order::SIDES.each do |side|
      update_by_side!(side, orders.filter { |o| o.side == side })
    end
  end

  def update_by_side!(side, orders)
    logger.debug "Update by side #{side} #{orders}"

    persisted_orders = fetch_active_orders(side)
    logger.debug "Fetched orders #{persisted_orders}"

    outdated_orders = find_outdated_orders(fetch_active_orders(side), orders)
    logger.debug "Outdated orders #{outdated_orders}"

    logger.debug "Cancel orders #{outdated_orders}"
    cancel_orders! outdated_orders

    orders_to_create = find_orders_to_create(orders, outdated_orders)
    logger.debug "Create orders #{outdated_orders}"
    create_orders! orders_to_create

    orders_to_create
  end

  private

  def find_orders_to_create(orders, outdated_orders)
    orders.filter do |order|
      !outdated_orders.find { |o| o.price == order.price }
    end
  end

  def fetch_active_orders(side)
    peatio_client
      .orders(market: market.peatio_symbol, type: SIDES_MAP.fetch(side), state: :wait)
      .map do |data|
      PersistedOrder.new(
        data.symbolize_keys.slice(*PersistedOrder.attribute_set.map(&:name))
      )
    end
  end

  def cancel_orders!(orders)
    orders.each do |order|
      peatio_client.cancel_order order.id
    end
  end

  def find_outdated_orders(persisted_orders, recent_orders)
    persisted_orders.filter do |po|
      !recent_orders.find { |o| o.price != po.price }.nil?
    end
  end

  def create_orders!(orders)
    orders.each do |order|
      peatio_client.create_order(
        market: market.peatio_symbol,
        ord_type: :limit,
        price: order.price,
        volume: order.volume,
        side: SIDES_MAP.fetch(order.side)
      )
      write_to_influx(order)
    end
  end

  def write_to_influx(order)
    Valera::InfluxDB.client
                    .write_point(
                      INFLUX_TABLE,
                      values: { "#{order.side}_volume": order.volume, "#{order.side}_price": order.price },
                      tags: { market: market.id, bot: name }
                    )
  end
end
