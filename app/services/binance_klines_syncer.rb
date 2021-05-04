class BinanceKlinesSyncer
  include AutoLogger
  INTERVAL = '1m'
  INFLUX_TABLE = 'binance_klines'

  attr_reader :market_symbol

  def initialize(market_symbol)
    @market_symbol = market_symbol
  end

  def perform
    logger.info "perform for #{market_symbol}"
    BinanceClient.instance.klines(symbol: market_symbol, interval: INTERVAL, limit: 1).each do |kline|
      InfluxWriter.perform_async(
        INFLUX_TABLE,
        {
          values: kline.as_json.merge(created_at: kline.closetime/1000),
          tags: { market: market_symbol }
        }
      )
    end
  end
end
