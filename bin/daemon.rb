#!/usr/bin/env ruby
# frozen_string_literal: true
APP_PATH = File.expand_path('../config/application', __dir__)
require_relative '../config/environment'

SdNotify.ready
God.instance
SdNotify.status("God was born!")
EM.run do
  Market.all.each do |market|
    Settings.drainer_classes.each do |drainer_class|
      drainer = drainer_class.new(market)
      drainer.attach
      God.logger.info "Attach #{drainer}"
      SdNotify.status("#{market} market drained")
    end
  end
end
SdNotify.stopping
