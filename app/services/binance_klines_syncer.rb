require 'valera/influxdb'
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
      data = {
        values: kline.to_influx_data,
        tags: { market: market_symbol }
      }
      Valera::InfluxDB
        .client
        .write_point(INFLUX_TABLE, data, "ns")
    end
  end
end
