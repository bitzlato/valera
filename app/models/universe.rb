class Universe
  INTERVAL = '1m'

  include AutoLogger

  attr_reader :market, :god, :options, :market, :botya

  def initialize(god: , market: , options: {})
    @god = god
    @botya = Botya.new(market: market.downcase, client: god.peatio_client)
    @options = options
    @market = market
  end

  def perform
    symbol = binance_symbol(market)
    klines = BinanceClient.instance.klines(symbol: symbol, interval: INTERVAL, limit: 1)

    # TODO Create value object
    input_data = OpenStruct.new(kline: klines.first)

    Processor
      .new(universe: self, market: market, input_data: input_data, options: options)
      .perform
  end

  private

  def binance_symbol(market)
    market.gsub('MCR', 'RUB')
  end
end
