class Processor
  include AutoLogger

  DEFAULT_VOLUMES = {
    ethbtc:       0.0001,
    ethusdt:      0.0001,
    btcusdt:      0.0001,
    btcmcr:       0.0001,
    ethmcr:       0.0001,
    usdtmcr:      1,
  }

  def initialize(botya: , market: , input_data:, options:, last_data:)
    @botya   = botya
    @market     = market
    @input_data = input_data
    @options    = options
    @last_data = last_data
  end

  def perform
    if input_data.kline.empty?
      logger.info "No kline data for market #{market} cancel orders"
      botya.cancel_orders!
    else
      logger.info "Perform market #{market} with kline #{input_data.kline}"
      bit_price = input_data.kline.low.to_d - input_data.kline.low.to_d * options.bit_place_threshold.value.to_d
      ask_price = input_data.kline.high.to_d + input_data.kline.high.to_d * options.ask_place_threshold.value.to_d

      create_order :buy, bit_price
      create_order :sell, ask_price
    end
  end

  private

  attr_reader :botya, :input_data, :market, :options, :last_data

  def create_order(side, price)
    volume = calculate_volume side
    botya.create_order! side, volume, price
    last_data.send "last_#{side}_order=", { volume: volume, price: price }.to_json
  end

  # Объём заявки
  #
  def calculate_volume(side)
    # TODO Высчитывать на основе чего-то там
    DEFAULT_VOLUMES[market.downcase.to_sym]
  end
end
