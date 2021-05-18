#!/usr/bin/env ruby
# frozen_string_literal: true
APP_PATH = File.expand_path('../config/application', __dir__)
require_relative '../config/environment'

SdNotify.ready
God.instance
SdNotify.status("God was born!")

loop do
  God.universes.each do |universe|
    universe.bump!
  end
end

SdNotify.stopping
