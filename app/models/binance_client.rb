class BinanceClient
  include Singleton

  KLine = Struct.new(:opentime,
                     :open,
                     :high,
                     :low,
                     :close,
                     :volume,
                     :closetime,
                     :quote_asset_volume,
                     :number_of_trades,
                     :taker_buy_asset_volume,
                     :taker_buy_quote_asset_volume,
                     :ignore)

  class KLine
    def to_s
      [high, low].join('->')
    end
    def empty?
      low.to_f == 0
    end
  end

  def self.build
    Binance::Client::REST.new api_key: ENV['BINANCE_API_KEY'], secret_key: ENV['BINANCE_SECRET_KEY']
  end

  attr_reader :client

  def initialize
    @client ||= self.class.build
  end

  def klines(*args)
    client.klines(*args).map { |r| KLine.new(*r) }
  end
end
