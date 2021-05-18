# frozen_string_literal: true

# Smartly updates private order book for market/account and logs changes.
#
# rubocop:disable Metrics/ClassLength
class OrdersUpdater
  include AutoLogger

  INFLUX_TABLE = 'processor'

  # If volume*price of order is changed on less then this percentage the order will not be changed
  AVAILABLE_DIVERGENCE = 0.01
  SIDES_MAP = { bid: 'buy', ask: 'sell' }.freeze

  attr_reader :client, :market, :logger, :name

  def initialize(client:, market:, name:)
    @market = market || raise('No market')
    @client =  client || raise('Nitneilc peatio client')
    @logger = ActiveSupport::TaggedLogging.new(_build_auto_logger)
                                          .tagged([self.class.name, market, client.name].join(' '))
    @name = name
  end

  # Updates orders on market. Cancel redundant orders and create new if necessary
  # @param Set[Order]
  def update!(orders)
    raise 'Must be a Set' unless orders.is_a? Set

    logger.info "Update with #{orders.to_a.join(',')}"
    Order::SIDES.map do |side|
      update_by_side!(side, orders.filter { |o| o.side == side })
    end.flatten
  end

  # Cancel all orders when bot stops
  def cancel!
    logger.debug 'Cancel all orders'
    Async do
      client.cancel_orders
    end
  end

  def update_by_side!(side, orders)
    logger.debug "[#{side}] Update by side #{side} #{orders}"

    persisted_orders = fetch_active_orders(side)
    logger.debug "[#{side}] Persisted orders #{persisted_orders}" if persisted_orders.any?

    outdated_orders = find_outdated_orders(persisted_orders, orders)
    logger.debug "[#{side}] Outdated orders #{outdated_orders}" if outdated_orders.any?

    if outdated_orders.any?
      logger.debug "[#{side}] Cancel orders #{outdated_orders}"
      cancel_orders! outdated_orders
    end

    orders_to_create = filter_orders_to_create(orders, persisted_orders - outdated_orders)
    if orders_to_create.present?

      logger.debug "[#{side}] Create orders #{orders_to_create}"
      created_orders = create_orders! orders_to_create
      logger.debug "[#{side}] Created orders #{created_orders}"

      created_orders
    else
      []
    end
  end

  private

  def filter_orders_to_create(orders, persisted_orders)
    orders.reject do |order|
      persisted_orders.find do |persisted_order|
        persisted_order.price == order.price && persisted_order.origin_volume == order.volume
      end
    end
  end

  # TODO: Move to drainer
  def fetch_active_orders(side)
    client
      .orders(market: market.peatio_symbol, type: SIDES_MAP.fetch(side), state: :wait)
      .map { |data| build_persisted_order data }
  end

  # "id"=>1085518,
  # "uuid"=>"eefb9c4e-ca2a-464c-b22d-520176c30637",
  # "side"=>"sell",
  # "ord_type"=>"limit",
  # "price"=>"50377.1418",
  # "avg_price"=>"0.0",
  # "state"=>"pending",
  # "market"=>"btcusdt",
  # "market_type"=>"spot",
  # "created_at"=>"2021-05-13T08:15:30Z",
  # "updated_at"=>"2021-05-13T08:15:30Z",
  # "origin_volume"=>"0.0001",
  # "remaining_volume"=>"0.0001",
  # "executed_volume"=>"0.0",
  # "maker_fee"=>"0.0",
  # "taker_fee"=>"0.0",
  # "trades_count"=>0
  def build_persisted_order(data)
    PersistedOrder.new(
      data.symbolize_keys.slice(*PersistedOrder.attribute_set.map(&:name))
    )
  end

  def cancel_orders!(orders)
    Async do
      orders.each do |order|
        client.cancel_order order.id
      end
    end
  end

  def find_outdated_orders(persisted_orders, recent_orders)
    persisted_orders.filter do |po|
      !recent_orders.find { |o| o.price != po.price }.nil?
    end
  end

  def create_orders!(orders)
    orders.map do |order|
      create_order! order
    rescue Errno::ECONNREFUSED => e
      logger.error e
    end
  end

  # @param order <Order>
  def create_order!(order)
    result = client.create_order(
      market: market.peatio_symbol,
      ord_type: :limit,
      price: order.price,
      volume: order.volume,
      side: SIDES_MAP.fetch(order.side)
    )
    created_order = build_persisted_order result
    write_to_influx(created_order, level: order.level)
    created_order
  rescue StandardError => e
    logger.error "Error #{e} creating order #{order}"
    report_exception e
  end

  def write_to_influx(order, level: 0)
    side = SIDES_MAP.invert.fetch(order.side)
    Valera::InfluxDB.client
                    .write_point(
                      INFLUX_TABLE,
                      values: { "#{side}_volume": order.origin_volume, "#{side}_price": order.price },
                      tags: { market: market.id, bot: name, level: level }
                    )
  end
end
# rubocop:enable Metrics/ClassLength
