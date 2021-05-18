# frozen_string_literal: true

# Bot universe for specific market
# Rename to Strategy
#
class Universe
  include AutoLogger
  # include UpdatePeatioBalance
  extend UniverseFinders

  attr_reader :peatio_client, :market, :name, :state, :comment, :logger, :updater, :stop_reason, :upstream_markets

  delegate :description, :settings_class, :state_class, to: :class

  def self.description
    raise 'undefined strategy'
  end

  def self.settings_class
    return [name, 'Settings'].join('::').constantize if constants.include? :Settings

    UniverseSettings
  end

  def self.state_class
    return [name, 'State'].join('::').constantize if constants.include? :State

    UniverseState
  end

  # @param name [String] key of bot from Rails credentials
  # @param market [Market]
  def initialize(name:, market:, peatio_client:, default_settings: {}, comment: nil)
    @name = name
    @market = market
    @default_settings = default_settings
    @peatio_client = peatio_client
    @state = state_class.find_or_create! id
    @comment = comment
    @logger = ActiveSupport::TaggedLogging.new(_build_auto_logger).tagged([self.class, id].join(' '))
    @updater = OrdersUpdater.new(market: market, peatio_client: peatio_client, name: name)
    # TODO customize used upstreams
    @upstreams = Upstream.all
    @upstream_markets = market.upstream_markets
  end

  def class_and_name
    "[#{self.class.name}]#{name}"
  end

  def reload
    settings.reload
    state.reload
    upstream_markets.each &:reload
    self
  end

  def title
    "[#{self.class.name}]#{id}"
  end
  alias to_s title

  def stop!(reason = 'No reason')
    settings.stop! reason
    logger.info "Stop with #{reason}"
    updater.cancel!
    state.update_attributes!(created_orders: [], current_orders: [])
  end

  def start!
    logger.info 'Start'
    settings.start!
    bump!
  end

  def notify_changes!
    # TODO compare with current state and bump if need
    bump!
  end

  # Change state
  # @param changes [Hash]
  def bump!(changes = {})
    reload
    logger.info "Bump with #{changes}"

    if settings.enabled && settings.status == UniverseSettings::ACTIVE_STATUS
      created_orders, current_orders = updater.update! build_orders
      state.update_attributes! created_orders: created_orders, current_orders: current_orders
    else
      updater.cancel! if state.created_orders.present? || state.current_orders.present?
      logger.info 'Does not update bot orders because bot is disabled or inactive. Cancel all orders'
      state.update_attributes! created_orders: [], current_orders: []
    end

    UniverseChannel.update self
  rescue StandardError => e
    report_exception e
    logger.error "#{self} #{e}"
  end

  def id
    [name, market.id].join('-')
  end
  alias to_param id

  def reset_settings!
    settings_class.new(id: id).update_attributes! @default_settings
    remove_instance_variable :@settings if instance_variable_defined? :@settings
  end

  def settings
    return @settings if instance_variable_defined? :@settings

    @settings = settings_class.find_or_create! id, @default_settings
  end

  private

  def build_orders
    Set.new(
      Order::SIDES.map do |side|
        build_order(side, calculate_price(side), calculate_volume(side))
      end.compact
    )
  end

  def build_order(side, price, volume, level = 0)
    if price.nil?
      logger.warn 'Skip order building for side because price is undefined'
      nil
    else
      logger.debug "build_order(#{side}, #{price}, #{volume})"
      Order.build(side: side, price: price, volume: volume, level: level)
    end
  end

  def calculate_price(_side)
    raise 'not implemented'
  end

  def calculate_volume(_side)
    raise 'not implemented'
  end
end
