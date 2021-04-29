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

  def initialize(botya: , market: , input_data:, options:)
    @botya   = botya
    @market     = market
    @input_data = input_data
    @options    = options
  end

  def perform
    if input_data.kline.empty?
      logger.info "No kline data for market #{market} cancel orders"
      botya.cancel_orders!
    else
      logger.info "Perform market #{market} with kline #{input_data.kline}"
      bit_price = input_data.kline.low.to_d - input_data.kline.low.to_d * options.bit_place_threshold.to_d
      ask_price = input_data.kline.high.to_d + input_data.kline.high.to_d * options.ask_place_threshold.to_d
      botya.create_order! :buy, calculate_volume(:buy), bit_price
      botya.create_order! :sell, calculate_volume(:sell), ask_price
    end
  end

  private

  attr_reader :botya, :input_data, :market, :options

  # Объём заявки
  #
  def calculate_volume(side)
    # TODO Высчитывать на основе чего-то там
    DEFAULT_VOLUMES[market.downcase.to_sym]
  end
end
