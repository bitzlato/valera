#!/usr/bin/env ruby
# frozen_string_literal: true
APP_PATH = File.expand_path('../config/application', __dir__)
require_relative '../config/environment'

SdNotify.ready
God.instance
SdNotify.status("God was born!")

EM.run do
  God.drainers.each do |drainer|
    God.logger.info "Attach #{drainer}"
    drainer.attach
  end
end
SdNotify.stopping
