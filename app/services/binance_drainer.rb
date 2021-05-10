# Connects to binance stream and store kline to internal influx
#
class BinanceDrainer
  MAPPING = {
    'bookTicker' => {
      'b' => :bidPrice,
      'B' => :bidQty,
      'a' => :askPrice,
      'A' => :askQty
    },

    'aggTrade' => {
      'p' => :tradePrice,
      'q' => :tradeQuantity
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
  attr_reader :market, :logger

  def initialize(market)
    @market = market
    @logger = ActiveSupport::TaggedLogging.new(_build_auto_logger).tagged(market)
  end

  def open(e)
    dump_headers e
    logger.info 'connected'
  end

  def error(e)
    # Possible e.message:
    # Errno::ECONNRESET
    Bugsnag.notify e.message do |b|
      b.meta_data = { :market_id => market.id }
    end
    logger.error "error (#{e.type}) with message #{e.message}"

    if e.message == Errno::ECONNRESET
      logger.warn 'Reattach'
      attach
    else
      binding.pry if Rails.env.development?
    end
  end

  def close(e=nil)
    # When ctrl-c
    # e.code == 1006
    # e.reason == ''
    dump_headers e
    logger.warn "closed with code #{e.code}"
  end

  def message(e)
    dump_headers e
    data = JSON.parse(e.data)
    logger.info data
    stream = data['stream'].split('@').last.split('_').first
    values = map data['data'], MAPPING[stream]
    write_to_influx values
    bump! values
  end

  def attach(client = nil)
    @client ||= client
    logger.info 'Attach'
    @client.multi :streams => [
      { :type => 'aggTrade', :symbol => market.binance_symbol },
      { :type => 'bookTicker', :symbol => market.binance_symbol },
      { :type => 'kline', :symbol => market.binance_symbol, :interval => '1m'}
    ], :methods => methods
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
      .write_point( INFLUX_TABLE, :values => data, :tags => { :market => market.id, :upstream => :binance })
  end

  def dump_headers(e)
    logger.debug e.target.headers.inspect
  end
end
