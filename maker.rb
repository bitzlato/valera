#!/usr/bin/env ruby
# frozen_string_literal: true

APP_PATH = File.expand_path('./config/application', __dir__)
require_relative './config/environment'

class Maker
  include AutoLogger

  def new
    SdNotify.ready
    God.instance
  end

  def perform
    God.strategies.each(&:start!)

    loop do
      God.strategies.each do |strategy|
        logger.debug "Perform strategy #{strategy}"
        strategy.perform
        logger.debug "Sleep for #{Settings.maker_sleep}"
        sleep Settings.maker_sleep
      rescue StandardError => e
        report_exception e
        logger.error e
      end
    rescue Interrupt => e
      logger.warn e
      God.strategies.each do |strategy|
        logger.debug "Stop strategy #{strategy}"
        strategy.stop! e.message.presence || e.inspect
      end
      raise e
    end

    SdNotify.stopping
  end
end

Maker.new.perform
