if ENV.true? 'COLLAPSE_AUTO_LOGGER'
  if ENV['COLLAPSE_AUTO_LOGGER'] == 'STDOUT'
    logger = Logger.new(STDOUT)
  else
    logger = Rails.logger
  end
  AutoLogger.logger_builder = -> (tag, default_formatter) {
    ActiveSupport::TaggedLogging
      .new(logger)
      .tagged(tag)
  }
end
