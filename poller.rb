#!/usr/bin/env ruby
# frozen_string_literal: true

APP_PATH = File.expand_path('./config/application', __dir__)
require_relative './config/environment'

class Poller
  include AutoLogger
  SAFE_ERRORS = [Faraday::ConnectionFailed, Velara::BaseClient::Error].freeze

  def initialize
    God.instance
    SdNotify.ready
  end

  def perform
    loop do
      God.polling_collectors.each do |collector|
        logger.debug("Collector #{collector} run update!")
        collector.update!
        logger.debug "Sleep for #{Settings.polling_sleep}"
        sleep Settings.polling_sleep
      rescue StandardError => e
        if SAFE_ERRORS.include? e
          logger.warn "Catch #{e} retry after 1 second"
          sleep 1
        else
          logger.error e
          report_exception e
          raise e
        end
      end
    end
    SdNotify.stopping
  end
end

Poller.new.perform
