#!/usr/bin/env ruby
# frozen_string_literal: true
APP_PATH = File.expand_path('./config/application', __dir__)
require_relative './config/environment'

God.instance
SdNotify.ready

SAFE_ERRORS = [ Faraday::ConnectionFailed, Peatio::Client::REST::Error ]

loop do
  God.polling_collectors.each do |collector|
    collector.update!
    sleep Settings.polling_sleep
  end
rescue StandardError => err
  if SAFE_ERRORS.include? err
    God.logger.warn "Catch #{err} retry after 1 second"
    sleep 1
    err.skip
  else
    report_exception err
  end
end
SdNotify.stopping
