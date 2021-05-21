#!/usr/bin/env ruby
# frozen_string_literal: true
APP_PATH = File.expand_path('./config/application', __dir__)
require_relative './config/environment'

SdNotify.ready
God.instance
SdNotify.status("God was born!")

God.strategies.each &:start!

loop do
  God.strategies.each do |strategy|
    strategy.perform
    sleep Settings.maker_sleep
  end
rescue Interrupt => exception
  God.logger.info exception
  God.strategies.each do |strategy|
    strategy.stop! exception.message.presence || exception.inspect
  end
  raise exception
rescue StandardError => err
  report_exception err
  God.logger.error err
  err.skip
end

SdNotify.stopping
