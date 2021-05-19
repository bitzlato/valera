#!/usr/bin/env ruby
# frozen_string_literal: true
APP_PATH = File.expand_path('../config/application', __dir__)
require_relative '../config/environment'

SdNotify.ready
God.instance
SdNotify.status("God was born!")

SAFE_ERRORS = [ Faraday::ConnectionFailed ]

EM.run do
  God.drainers.each do |drainer|
    God.logger.info "Attach #{drainer}"
    drainer.attach
  end
rescue => err
  if SAFE_ERRORS.include? err
    God.logger.warn "Catch #{err} retry after 1 second"
    sleep 1
    err.skip
  else
    report_exception err
  end
end
SdNotify.stopping
