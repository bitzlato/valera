# Connects to binance stream and store kline to internal influx
#
class BinanceDrainer
  MAPPING = {
    'bookTicker' => {
      'b' => :bidPrice,
      'B' => :bidQty,
      'a' => :askPrice,
      'A' => :askQty,
    },

    'aggTrade' => {
      'p' => :tradePrice,
      'q' => :tradeQuantity,
    },

    'kline' => {
      'o' => :open,
      'c' => :close,
      'h' => :high,
      'l' => :low,
      'v' => :volume
    }
  }

  KEYS = MAPPING.values.map(&:values).flatten

  INFLUX_TABLE = 'upstream'
  include AutoLogger
  attr_reader :market

  def initialize(market)
    @market = market
    @logger = ActiveSupport::TaggedLogging.new _build_auto_logger
  end

  def open(_e)
    logger.info "connected"
  end

  def error(e)
    logger.error e
  end

  def close(_e=nil)
    logger.info 'closed'
  end

  def message(e)
    data = JSON.parse(e.data)
    logger.info data
    stream = data['stream'].split('@').last.split('_').first
    values = map data['data'], MAPPING[stream]
    write_to_influx values
    bump! values
  end

  def attach(client)
    client.multi streams: [
      { type: 'aggTrade', symbol: market.binance_symbol },
      { type: 'bookTicker', symbol: market.binance_symbol },
      { type: 'kline', symbol: market.binance_symbol, interval: '1m'},
    ], methods: methods
  end

  private

  def methods
    %i[open message error close].each_with_object({}) do |m, a|
      a[m] = method m
    end
  end

  def bump!(data)
    market.universes.each do |universe|
      universe.bump! data
    end
  end

  def map(data, mapping)
    data = data['k'] if data.has_key?('k') && data['k'].is_a?(Hash)
    data.each_with_object({}) do |p, a|
      key, value = p
      a[mapping[key]] = value.to_d if mapping.has_key? key
    end
  end

  def write_to_influx(data)
    Valera::InfluxDB.client
      .write_point( INFLUX_TABLE, values: data, tags: { market: market.id, upstream: :binance })
  end

  def logger
    @logger.tagged(market)
  end
end
