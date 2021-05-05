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

  def initialize(botya: , market: , options:)
    @botya   = botya
    @market     = market
    @options    = options
    @bid_place_threshold = options.bid_place_threshold.value.to_d
    @ask_place_threshold = options.ask_place_threshold.value.to_d
  end

  # @param input_data [InputData]
  def perform(input_data)
    bid_price = input_data.bidPrice - input_data.bidPrice * @bid_place_threshold
    ask_price = input_data.askPrice + input_data.askPrice * @ask_place_threshold

    create_order :buy, bid_price
    create_order :sell, ask_price
    logger.info "(#{botya.name}) Perform market #{market} with input_data #{input_data} -> #{bid_price} #{ask_price}"

    write_to_influx ask_price, bid_price
  end

  private

  attr_reader :botya, :market, :options

  def write_to_influx(ask_price, bid_price)
    Valera::InfluxDB.client
      .write_point(
        INFLUX_TABLE,
        values: { botAsk: ask_price, botBid: bid_price, bid_place_threshold: @bid_place_threshold, ask_place_threshold: @ask_place_threshold },
        tags: { market: market.id, bot: botya.name }
    )
  end

  def create_order(side, price)
    volume = calculate_volume side
    botya.create_order! side, volume, price
    # last_data.send "last_#{side}_order=", { volume: volume, price: price }.to_json
  end

  # Объём заявки
  #
  def calculate_volume(side)
    # TODO Высчитывать на основе чего-то там
    DEFAULT_VOLUMES[market.symbol.downcase.to_sym]
  end
end
