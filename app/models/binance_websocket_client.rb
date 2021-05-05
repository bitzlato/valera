# Connects to binance stream and store kline to internal influx
#
class BinanceWebsocketClient
  include AutoLogger
  attr_reader :market

  def initialize(market)
    @market = market
    @logger = ActiveSupport::TaggedLogging.new _build_auto_logger
  end

  def open(_e)
    logger.info "connected"
  end

  def message(e)
    data = JSON.parse e.data
    logger.info data
  end

  def error(e)
    logger.error e
  end

  def close(_e=nil)
    logger.info 'closed'
  end

  def methods
    %i[open message error close].each_with_object({}) do |m, a|
      a[m] = method m
    end
  end

  private

  def symbolize_and_digitalize_values(values)
    values.each_with_object({}) do |p, a|
      a[p.first.to_sym] = p.second.to_d
    end
  end

  def logger
    @logger.tagged(market)
  end
end

## Example: {"e":"kline","E":1620207374750,"s":"ETHUSDT","k":{"t":1620207360000,"T":1620207419999,"s":"ETHUSDT","i":"1m","f":394233699,"L":394233991,"o":"3356.99000000","c":"3355.99000000","h":"3357.00000000","l":"3353.68000000","v":"162.57455000","n":293,"x":false,"q":"545516.11111290","V":"116.22667000","Q":"389997.85720610","B":"0"}}
#def kline_message(e)
  #data = JSON.parse e.data
  #values = %i[open close low high volume].each_with_object({}) do |f,a|
    #a[f] = data.dig('k', f.slice(0)).to_d
  #end
  #logger.info  [data['E'], values].join(':')
  #Valera::InfluxDB.client
    #.write_point(
      #INFLUX_TABLE,
      #values: values,
      #tags: { market: market, upstream: :binance },
      #timestamp: data['E']
  #)
#end

