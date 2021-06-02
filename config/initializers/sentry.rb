Sentry.init do |config|
  # config.dsn = 'https://9b238dde9c054004947f9d5bb0b636e4@o244676.ingest.sentry.io/5796426'
  config.breadcrumbs_logger = [:active_support_logger, :http_logger]

  # Set tracesSampleRate to 1.0 to capture 100%
  # of transactions for performance monitoring.
  # We recommend adjusting this value in production
  config.traces_sample_rate = 0.5
  # or
  config.traces_sampler = lambda do |context|
    true
  end

  config.send_default_pii = true
end
