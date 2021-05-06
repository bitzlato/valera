#!/usr/bin/env ruby
require_relative "config/environment"

client = Binance::Client::WebSocket.new

God.instance

EM.run do
  # Pass a symbol and event handler Hash to connect and process events
  Market.all.each do |market|
    BinanceDrainer
      .new(market)
      .attach(client)
  end
end
