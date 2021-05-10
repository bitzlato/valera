# frozen_string_literal: true

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
      low.to_f.zero?
    end

    def to_influx_data
      to_h.symbolize_keys.merge(created_at: closetime / 1000)
    end
  end

  def self.build
    Binance::Client::REST.new api_key: ENV['BINANCE_API_KEY'], secret_key: ENV['BINANCE_SECRET_KEY']
  end

  attr_reader :client

  def initialize
    @client = self.class.build
  end

  def klines(*args)
    data = client.klines(*args)
    # TODO: check for errors
    data.map { |r| KLine.new(*r.map(&:to_d)) }
  end

  def method_missing(method, *args)
    client.send method, *args
  end
end
