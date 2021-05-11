#!/usr/bin/env ruby
# frozen_string_literal: true
APP_PATH = File.expand_path('../config/application', __dir__)
require_relative '../config/environment'

SdNotify.ready

client = Binance::Client::WebSocket.new

God.instance
EM.run do
  # Pass a symbol and event handler Hash to connect and process events
  Market.all.each do |market|
    BinanceDrainer
      .new(market)
      .attach(client)
     SdNotify.status("#{market} market drained")
  end
end
SdNotify.stopping
