# frozen_string_literal: true

# Smartly updates private order book for market/account and logs changes.
#
class OrdersUpdater
  include AutoLogger

  THREADS = 8

  # If volume*price of order is changed on less then this percentage the order will not be changed
  AVAILABLE_DIVERGENCE = 0.01

  attr_reader :account, :market, :logger, :name

  delegate :client, to: :account

  def initialize(account:, market:, name:)
    @market = market || raise('No market')
    @account = account || raise('No account')
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
      update_by_side!(side, orders.filter { |o| o.side.to_s == side.to_s })
    end.flatten.compact
  end

  # Cancel all orders when bot stops
  def cancel!
    logger.debug 'Cancel all orders'
    client.cancel_orders
  end

  def update_by_side!(side, orders)
    logger.debug "[#{side}] Update by side #{side} #{orders}"

    persisted_orders = account.active_orders.filter { |o| o.side? side }
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

  def cancel_orders!(orders)
    orders.each do |order|
      client.cancel_order order.id
    end
  end

  def find_outdated_orders(persisted_orders, recent_orders)
    persisted_orders.filter do |po|
      !recent_orders.find { |o| o.price != po.price }.nil?
    end
  end

  def create_orders!(orders)
    Parallel.map orders.map, in_threads: THREADS do |order|
      create_order! order
    rescue Errno::ECONNREFUSED, Peatio::Client::REST::Error => e
      logger.error e
      []
    end
  end

  # @param order <Order>
  def create_order!(order)
    created_order = client.create_order(
      market: market.peatio_symbol,
      ord_type: :limit,
      price: order.price,
      volume: order.volume,
      side: order.side
    )
    write_to_influx(created_order, level: order.level)
    created_order
  rescue StandardError => e
    logger.error "Error #{e} creating order #{order}"
    report_exception e
  end

  def write_to_influx(order, level: 0)
    Valera::InfluxDB.client
                    .write_point(
                      Settings.influx.orders_updater,
                      values: { "#{order.side}_volume": order.origin_volume,
                                "#{order.side}_price": order.price },
                      tags: { market: market.id, bot: name, level: level }
                    )
  end
end
