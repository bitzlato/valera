# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

# Connects to binance stream and store kline to internal influx
#
class BinanceWebsocketDrainer < WebsocketDrainer
  include MarketDrainer

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
  }.freeze

  KEYS = MAPPING.values.map(&:values).flatten

  STREAMS = [
    # TODO: Collect necessary data from strategy configurations
    # { type: 'aggTrade' },
    # { type: 'kline', interval: '1m' }
    { type: 'bookTicker' }
  ].freeze

  private

  def streams
    STREAMS.map { |s| s.merge symbol: market.binance_symbol || raise("No binance_symbol for #{market}")}
  end

  def map(data)
    stream = data['stream'].split('@').last.split('_').first
    values = data['data']
    values = values['k'] if values.key?('k') && values['k'].is_a?(Hash)
    simple_map values, MAPPING[stream]
  end

  def ws_client
    @ws_client ||= Binance::Client::WebSocket.new
  end
end
