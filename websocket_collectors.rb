#!/usr/bin/env ruby
# frozen_string_literal: true

APP_PATH = File.expand_path('./config/application', __dir__)
require_relative './config/environment'

God.instance
SdNotify.ready

SAFE_ERRORS = [Faraday::ConnectionFailed, Peatio::Client::REST::Error].freeze

EM.run do
  God.websocket_collectors.each do |drainer|
    God.logger.info "Attach #{drainer}"
    drainer.attach
  end
rescue StandardError => e
  if SAFE_ERRORS.include? e
    God.logger.warn "Catch #{e} retry after 1 second"
    sleep 1
    e.skip
  else
    report_exception e
  end
end
SdNotify.stopping
