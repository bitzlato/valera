#!/usr/bin/env ruby
# frozen_string_literal: true
APP_PATH = File.expand_path('../config/application', __dir__)
require_relative '../config/environment'

SdNotify.ready
God.instance
SdNotify.status("God was born!")
EM.run do
  # Pass a symbol and event handler Hash to connect and process events
  Market.all.each do |market|
    God.drainers.each do |drainer|
      drainer.new(market).attach
      SdNotify.status("#{market} market drained")
    end
  end
end
SdNotify.stopping
