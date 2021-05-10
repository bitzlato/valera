# frozen_string_literal: true

Bugsnag.configure do |config|
  config.app_version = AppVersion.format('%M.%m.%p')
  # config.ignore_classes << HumanizedError
  config.send_code = true
  config.send_environment = true
  config.notify_release_stages = %w[production staging]
end
