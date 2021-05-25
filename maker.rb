#!/usr/bin/env ruby
# frozen_string_literal: true

APP_PATH = File.expand_path('./config/application', __dir__)
require_relative './config/environment'

SdNotify.ready
God.instance
SdNotify.status('God was born!')

God.strategies.each(&:start!)

loop do
  God.strategies.each do |strategy|
    strategy.perform
    sleep Settings.maker_sleep
  rescue StandardError => e
    report_exception e
    God.logger.error e
  end
rescue Interrupt => e
  God.logger.info e
  God.strategies.each do |strategy|
    strategy.stop! e.message.presence || e.inspect
  end
  raise e
end

SdNotify.stopping
