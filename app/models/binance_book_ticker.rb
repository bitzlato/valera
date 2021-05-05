# Connects to binance stream and store kline to internal influx
#
class BinanceBookTicker < BinanceWebsocketClient
  INFLUX_TABLE = 'upstream'

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

  # Input example (e.data)
  #{
  #"u":400900217,     // order book updateId
  #"s":"BNBUSDT",     // symbol
  #"b":"25.35190000", // best bid price
  #"B":"31.21000000", // best bid qty
  #"a":"25.36520000", // best ask price
  #"A":"40.66000000"  // best ask qty
  #}
  def message_bookTicker(data)
    write_to_influx_bookTicker data
    market.universes.each do |universe|
      universe.bump!(map data)
    end
  end

  # {"e"=>"aggTrade", "E"=>1620220311277, "s"=>"BTCUSDT", "a"=>720884177, "p"=>"55640.15000000", "q"=>"0.01365800", "f"=>810221350, "l"=>810221350, "T"=>1620220311276, "m"=>true, "M"=>true}
  def message_aggTrade(data)
    logger.info 'aggTrade' + data.to_s
  end

  # {"e"=>"kline", "E"=>1620220343059, "s"=>"BTCUSDT", "k"=>{"t"=>1620220320000, "T"=>1620220379999, "s"=>"BTCUSDT", "i"=>"1m", "f"=>810221464, "L"=>810221897, "o"=>"55632.54000000", "c"=>"55622.20000000", "h"=>"55632.54000000", "l"=>"55620.83000000", "v"=>"10.41397000", "n"=>434, "x"=>false, "q"=>"579326.65114897", "V"=>"4.60200100", "Q"=>"256007.38175658", "B"=>"0"}}
  def message_kline_1m(data)
    logger.info 'kline' + data.to_s
  end

  def message(e)
    data = JSON.parse(e.data)
    stream = data['stream'].split('@').last.split('_').first
    values = map data['data'], MAPPING[stream]
    write_to_influx values
    bump! values
  end

  def bump!(data)
    market.universes.each do |universe|
      universe.bump! data
    end
  end

  def attach(client)
    client.multi streams: [
      { type: 'aggTrade', symbol: market.binance_symbol },
      { type: 'bookTicker', symbol: market.binance_symbol },
      { type: 'kline', symbol: market.binance_symbol, interval: '1m'},
    ], methods: methods
    #client.single stream: { type: 'bookTicker', symbol: market.binance_symbol }, methods: methods
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
end
