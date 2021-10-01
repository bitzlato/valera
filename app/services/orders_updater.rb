# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

# Smart updates private order book for market/account and logs changes.
#
# rubocop:disable Metrics/ClassLength
class OrdersUpdater
  include AutoLogger

  ErrorInfo = Struct.new(:order, :message, :error)

  THREADS = 8

  # If volume*price of order is changed on less then this percentage the order will not be changed
  AVAILABLE_DIVERGENCE = 0.01

  attr_reader :account, :market, :logger, :name, :errors

  delegate :client, to: :account

  def initialize(account:, market:, name:, logger: nil)
    @market = market || raise('No market')
    @account = account || raise('No account')
    @logger = logger || ActiveSupport::TaggedLogging
              .new(_build_auto_logger)
              .tagged([self.class.name, market, client.try(:name), client.try(:endpoint)].compact.join(' '))
    @name = name
    @errors = []
    @changed = false
  end

  # Updates orders on market. Cancel redundant orders and create new if necessary
  # @param Set[Order]
  def update!(orders, update_active_orders: true)
    raise 'Must be a Set' unless orders.is_a? Set

    @errors = []
    account.update_active_orders! if update_active_orders

    @changed = false
    logger.info "Update request #{po orders}"
    created_orders = Order::SIDES.map do |side|
      update_by_side!(side, orders.filter { |o| o.side.to_s == side.to_s })
    end.flatten.compact

    logger.info 'All orders up to date, nothing changed' unless @changed
    created_orders
  end

  def start!
    @errors = []
    @changed = false
  end

  # Cancel all orders when bot stops
  def cancel!
    logger.info "Cancel all orders for market #{market}"
    # TODO: Тут может быть не только peatio_symbol, нужно определять символ по клиенту
    canceled_orders = client.cancel_orders market: market.peatio_symbol
    logger.info "Orders canceled #{canceled_orders.count}"
  end

  def update_by_side!(side, required_orders)
    logger.debug "[#{side}] Update by side #{side} #{required_orders}"

    persisted_orders = active_orders(side)
    logger.debug "[#{side}] Persisted orders #{po persisted_orders}"

    outdated_orders, orders_to_create = calculate_orders Set.new(persisted_orders), Set.new(required_orders)
    logger.debug "[#{side}] Outdated orders: #{po outdated_orders}], orders to create: #{po orders_to_create}"

    created_orders = create_orders! orders_to_create if orders_to_create.any?
    cancel_orders! outdated_orders if outdated_orders.any?

    created_orders
  end

  def active_orders(side)
    account.active_orders.filter { |o| o.market == market && o.side?(side) }
  end

  def cancel_orders!(orders)
    @changed = true
    logger.info "Cancel orders #{po orders}"
    orders.each do |order|
      client.cancel_order order.id
    rescue Valera::BaseClient::Error => e
      @errors << ErrorInfo.new(order: order, message: "Error canceling order #{order} -> #{e}", error: e)
    end
  end

  # rubocop:disable Style/MultilineBlockChain
  def create_orders!(orders)
    @changed = true
    logger.info "Create orders #{po orders}"
    Parallel.map orders.map, in_threads: THREADS do |order|
      create_order! order
    rescue Valera::BaseClient::Error, StandardError => e
      logger.warn "#{e} for order #{order}"
      @errors << ErrorInfo.new(order: order, message: "Error creating order #{order} -> #{e}", error: e)
      nil
    end.compact.tap do |created_orders|
      logger.debug "Created orders #{created_orders}"
    end
  end
  # rubocop:enable Style/MultilineBlockChain

  private

  # Present orders
  def po(orders)
    "[#{orders.to_a.join('; ')}]"
  end

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

  # @param order <Order>
  def create_order!(order)
    raise "WTF! Order has zero price #{order}" if order.price.zero?

    created_order = client.create_order(
      market: market,
      ord_type: :limit,
      price: order.price,
      volume: order.volume,
      side: order.side
    ) || raise("No order created for #{order}")
    write_to_influx(created_order, level: order.level)
    created_order
  rescue Valera::BaseClient::InsufficientBalance, StandardError => e
    report_exception e, true, order: order unless e.is_a? Valera::BaseClient::InsufficientBalance
    raise e
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
# rubocop:enable Metrics/ClassLength
