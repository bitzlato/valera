# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

if ENV.true? 'COLLAPSE_AUTO_LOGGER'
  logger = if ENV['COLLAPSE_AUTO_LOGGER'] == 'STDOUT'
             Logger.new($stdout)
           else
             Rails.logger
           end
  logger.level = ENV['AUTO_LOGGER_LEVEL'] if ENV.key? 'AUTO_LOGGER_LEVEL'
  AutoLogger.logger_builder = lambda { |tag, _default_formatter|
    ActiveSupport::TaggedLogging
      .new(logger)
      .tagged(tag)
  }
  Rails.logger = logger
end
