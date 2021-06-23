#!/usr/bin/env ruby
# frozen_string_literal: true

APP_PATH = File.expand_path('./config/application', __dir__)
require_relative './config/environment'

class WebSocketCollectors
  include AutoLogger
  SAFE_ERRORS = [Faraday::ConnectionFailed, Peatio::Client::REST::Error].freeze

  def initialize
    God.instance
    SdNotify.ready
  end

  def perform
    logger.info('Start')
    EM.run do
      God.websocket_collectors.each do |drainer|
        logger.debug "Attach #{drainer}"
        drainer.attach
      end
    rescue StandardError => e
      if SAFE_ERRORS.include? e
        logger.warn "Catch #{e} retry after 1 second"
        sleep 1
        e.skip
      else
        logger.error e
        report_exception e
      end
    end
    logger.info('Stop')
    SdNotify.stopping
  end
end

WebSocketCollectors.new.perform
