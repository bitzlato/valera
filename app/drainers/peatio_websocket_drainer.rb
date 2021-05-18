# frozen_string_literal: true

# Connects to binance stream and store kline to internal influx
#
class PeatioWebsocketDrainer < WebsocketDrainer
  MAPPING = {
    'open' => :open,
    'high' => :high,
    'low' => :low,
    'volume' => :volume,
    'avg_price' => :avgPrice
  }.freeze

  KEYS = MAPPING.values.freeze

  STREAMS = [[:public, 'global.tickers']].freeze

  private

  def streams
    STREAMS
  end

  # rubocop:disable Layout/LineLength
  # {"global.tickers"=>
  # {"btcmcr"=>{"amount"=>"0.0", "at"=>"1620814768", "avg_price"=>"0.0", "high"=>"0.0", "last"=>"3426.9238", "low"=>"0.0", "open"=>"0.0", "price_change_percent"=>"+0.00%", "volume"=>"0.0"},
  # "btcusdt"=>{"amount"=>"0.006", "at"=>"1620814768", "avg_price"=>"57017.127265", "high"=>"57208.3808", "last"=>"57160.1019", "low"=>"56455.2017", "open"=>"56455.2017", "price_change_percent"=>"+1.25%", "volume"=>"342.10276359"},
  # "ethbtc"=>{"amount"=>"0.0", "at"=>"1620814768", "avg_price"=>"0.0", "high"=>"0.0", "last"=>"0.0607", "low"=>"0.0", "open"=>"0.0", "price_change_percent"=>"+0.00%", "volume"=>"0.0"},
  # "ethmcr"=>{"amount"=>"0.0", "at"=>"1620814768", "avg_price"=>"0.0", "high"=>"0.0", "last"=>"253848.4", "low"=>"0.0", "open"=>"0.0", "price_change_percent"=>"+0.00%", "volume"=>"0.0"},
  # "ethusdt"=>{"amount"=>"0.0", "at"=>"1620814768", "avg_price"=>"0.0", "high"=>"0.0", "last"=>"3370.5454", "low"=>"0.0", "open"=>"0.0", "price_change_percent"=>"+0.00%", "volume"=>"0.0"},
  # "usdtmcr"=>{"amount"=>"0.0", "at"=>"1620814768", "avg_price"=>"0.0", "high"=>"0.0", "last"=>"75.383", "low"=>"0.0", "open"=>"0.0", "price_change_percent"=>"+0.00%", "volume"=>"0.0"}}}
  # rubocop:enable Layout/LineLength

  def map(data)
    tickers = data.dig('global.tickers', market.peatio_symbol)
    throw :ignoreMessage if tickers.blank?
    simple_map tickers, MAPPING
  end

  def client
    @client ||= Peatio::Client::WebSocket.new(base_url: ENV.fetch('PEATIO_WEBSOCKET_URL'))
  end
end
