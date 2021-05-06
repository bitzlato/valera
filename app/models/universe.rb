# Bot universe for specific market
class Universe
  INFLUX_TABLE = 'processor'

  include AutoLogger
  include UpdatePeatioBalance
  extend UniverseFinders

  attr_reader :peatio_client, :market, :name, :state, :description, :settings, :botya

  # @param name [String] key of bot from Rails credentials
  # @param market [Market]
  def initialize(name:, market:, peatio_client:, default_settings: {}, description: nil)
    @name = name
    @market = market
    @default_settings = default_settings
    @peatio_client = peatio_client
    @botya = Botya.new(market: market, peatio_client: peatio_client, name: name)
    @settings = UniverseSettings.find_or_build id, default_settings
    reset_settings! if @settings.blank?
    @state = UniverseState.find_or_build id
    @description = description
  end

  def title
    "#{self.class.name}[#{name}]"
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
    settings.update_attributes @default_settings
  end

  private

  def perform
    bid_price = state.bidPrice + state.bidPrice * settings.bid_place_threshold
    ask_price = state.askPrice + state.askPrice * settings.ask_place_threshold

    logger.info "(#{botya.name}) Perform market #{market} with state #{state} -> #{bid_price} #{ask_price}"
    orders = []
    orders << create_order(:buy, bid_price)
    orders << create_order(:sell, ask_price)
    orders.compact
  end

  def create_order(side, price)
    volume = calculate_volume side
    botya.create_order! side, volume, price
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
    settings.volume
  end

  def write_to_influx(side, volume, price)
    Valera::InfluxDB.client
      .write_point(
        INFLUX_TABLE,
        values: { "volume_#{side}": volume, "price_#{side}": price },
        tags: { market: market.id, bot: botya.name }
    )
  end
end
