# Bot universe for specific market
class Universe
  INFLUX_TABLE = 'processor'

  include AutoLogger
  include UpdatePeatioBalance
  extend UniverseFinders

  attr_reader :peatio_client, :market, :name, :state, :description, :settings, :botya

  delegate :settings_class, :state_class, to: :class

  # @param name [String] key of bot from Rails credentials
  # @param market [Market]
  def initialize(name:, market:, peatio_client:, default_settings: {}, description: nil)
    @name = name
    @market = market
    @default_settings = default_settings
    @peatio_client = peatio_client
    @botya = Botya.new(market: market, peatio_client: peatio_client, name: name)
    @state = state_class.find_or_build id
    @description = description
  end

  def self.settings_class
    UniverseSettings
  end

  def self.state_class
    UniverseState
  end

  def reload
    settings.restore!
    state.restore!
    self
  end


  def title
    "#{name}[#{self.class.name}]"
  end
  alias_method :to_s, :title

  # Change state
  # @param changes [Hash]
  def bump!(changes)
    state.assign_attributes changes
    update_peatio_balances!
    logger.info "Perform #{to_s} with #{state}"

    orders = perform

    state.assign_attributes last_orders: orders
    state.save!
  rescue => err
    report_exception err
    logger.error "#{to_s} #{err}"
  end

  def id
    [name, market.id].join(':')
  end
  alias_method :to_param, :id

  def reset_settings!
    settings_class.new(id: id).update_attributes @default_settings
    remove_instance_variable :@settings if instance_variable_defined? :@settings
  end

  def settings
    return @settings if instance_variable_defined? :@settings
    @settings = settings_class.find_or_build id, @default_settings
  end

  private

  def perform
    ask_price = state.askPrice + state.askPrice * settings.ask_place_threshold/100
    bid_price = state.bidPrice + state.bidPrice * settings.bid_place_threshold/100

    logger.info "(#{botya.name}) Perform market #{market} with state #{state} -> #{bid_price} #{ask_price}"
    orders = []
    orders << create_order(:ask, ask_price)
    orders << create_order(:bid, bid_price)
    orders.compact
  end

  EX_SIDES = { bid: :buy, ask: :sell }

  def create_order(side, price)
    volume = calculate_volume side
    botya.create_order! EX_SIDES.fetch(side), volume, price
    write_to_influx side, volume, price
    { side: side, price: price, volume: volume }
  rescue => err
    report_exception err
    logger.error err
    nil
  end

  # Объём заявки
  #
  def calculate_volume(side)
    # TODO Высчитывать на основе чего-то там
    settings.send side.to_s+'_volume'
  end

  def write_to_influx(side, volume, price)
    Valera::InfluxDB.client
      .write_point(
        INFLUX_TABLE,
        values: { "#{side}_volume": volume, "#{side}_price": price },
        tags: { market: market.id, bot: name }
    )
  end
end
