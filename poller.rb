#!/usr/bin/env ruby
# frozen_string_literal: true

APP_PATH = File.expand_path('./config/application', __dir__)
require_relative './config/environment'

God.instance
SdNotify.ready

SAFE_ERRORS = [Faraday::ConnectionFailed, Peatio::Client::REST::Error].freeze

loop do
  God.polling_collectors.each do |collector|
    collector.update!
    sleep Settings.polling_sleep
  rescue StandardError => e
    God.logger.error e
    if SAFE_ERRORS.include? e
      God.logger.warn "Catch #{e} retry after 1 second"
      sleep 1
      e.skip
    else
      report_exception e
    end
  end
end
SdNotify.stopping
