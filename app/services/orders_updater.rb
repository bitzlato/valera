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
      .tagged([self.class.name, market, client.try(:name), client.try(:endpoint)].join(' '))
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
    canceled_orders = client.cancel_orders
    logger.debug "Orders canceled #{canceled_orders.count}"
  end

  def update_by_side!(side, required_orders)
    logger.debug "[#{side}] Update by side #{side} #{required_orders}"

    persisted_orders = active_orders(side)
    logger.debug "[#{side}] Persisted orders #{persisted_orders}"

    outdated_orders, orders_to_create = calculate_orders Set.new(persisted_orders), Set.new(required_orders)
    logger.debug "[#{side}] Outdated orders: #{outdated_orders}, orders to create: #{orders_to_create}"

    cancel_orders! outdated_orders if outdated_orders.any?

    return [] if orders_to_create.empty?

    create_orders! orders_to_create
  end

  def active_orders(side)
    account.active_orders.filter { |o| o.market == market && o.side?(side) }
  end

  private

  def calculate_orders(persisted_orders, required_orders)
    persisted_orders_to_skip = Set.new
    required_orders_to_skip = Set.new

    required_orders.each do |required_order|
      persisted_orders.each do |persisted_order|
        next if required_orders_to_skip.member? required_order

        if required_order.suitable? persisted_order
          persisted_orders_to_skip << persisted_order
          required_orders_to_skip << required_order
        end
      end
    end

    orders_to_cancel = persisted_orders - persisted_orders_to_skip
    orders_to_create = required_orders - required_orders_to_skip

    if orders_to_create.count > required_orders.count
      raise "Too much orders to create #{orders_to_create.count} > #{required_orders.count}"
    end

    if persisted_orders_to_skip.count + orders_to_create.count > required_orders.count
      raise "Too much combined orders #{persisted_orders_to_skip.count}+#{orders_to_create.count} > #{required_orders.count}" # rubocop:disable Layout/LineLength
    end

    [orders_to_cancel, orders_to_create]
  end

  def cancel_orders!(orders)
    logger.debug "Cancel orders #{orders}"
    orders.each do |order|
      client.cancel_order order.id
    end
  end

  # rubocop:disable Style/MultilineBlockChain
  def create_orders!(orders)
    Parallel.map orders.map, in_threads: THREADS do |order|
      create_order! order
    rescue Errno::ECONNREFUSED, Peatio::Client::REST::Error => e
      logger.error e
      []
    end.tap do |created_orders|
      logger.debug "Created orders #{created_orders}"
    end
  end
  # rubocop:enable Style/MultilineBlockChain

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
