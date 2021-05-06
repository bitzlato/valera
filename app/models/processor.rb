class Processor
  include AutoLogger
  INFLUX_TABLE = 'processor'

  DEFAULT_VOLUMES = {
    ethbtc:       0.0001,
    ethusdt:      0.0001,
    btcusdt:      0.0001,
    btcmcr:       0.0001,
    ethmcr:       0.0001,
    usdtmcr:      1,
  }

  def initialize(botya: , market: , settings:)
    @botya   = botya
    @market     = market
    @settings    = settings
    @bid_place_threshold = settings.bid_place_threshold
    @ask_place_threshold = settings.ask_place_threshold
  end

  # @param state [UniverseState]
  def perform(state)
    bid_price = state.bidPrice + state.bidPrice * @bid_place_threshold
    ask_price = state.askPrice + state.askPrice * @ask_place_threshold

    logger.info "(#{botya.name}) Perform market #{market} with state #{state} -> #{bid_price} #{ask_price}"
    orders = []
    orders << create_order(:buy, bid_price)
    orders << create_order(:sell, ask_price)
    orders.compact
  end

  private

  attr_reader :botya, :market, :settings

  def write_to_influx(side, volume, price)
    Valera::InfluxDB.client
      .write_point(
        INFLUX_TABLE,
        values: { "volume_#{side}": volume, "price_#{side}": price },
        tags: { market: market.id, bot: botya.name }
    )
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
    DEFAULT_VOLUMES[market.symbol.downcase.to_sym]
  end
end
