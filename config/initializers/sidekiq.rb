# frozen_string_literal: true

require 'sidekiq'
Sidekiq.default_worker_options = { 'backtrace' => true }

if Rails.env.development? || Rails.env.production? || Rails.env.staging? || ENV['SIDEKIQ_ASYNC']

  Sidekiq.logger = ActiveSupport::Logger.new Rails.root.join './log/sidekiq.log'
  Sidekiq.configure_server do |config|
    config.redis =  { url: ENV.fetch('VALERA_SIDEKIQ_REDIS_URL', 'redis://localhost:6379/4') }
    config.error_handlers << proc do |ex, context|
      Bugsnag.notify ex do |b|
        b.meta_data = context
      end
    end
    Sidekiq.logger.info "Configure server for application #{AppVersion}"
  end

  Sidekiq.configure_client do |config|
    config.redis = { url: ENV.fetch('VALERA_SIDEKIQ_REDIS_URL', 'redis://localhost:6379/4') }
    Sidekiq.logger.info "Configure server for application #{AppVersion}"
  end

elsif Rails.env.test?
  require 'sidekiq/testing/inline'
  Sidekiq::Testing.fake!
else

  raise "Not supported env #{Rails.env}"
end


#CRONTAB_FILE = "./config/sidekiq_crontab.yml"

#if Rails.env.staging? || Rails.env.production? || ENV.true?('LOAD_SIDEKIQ_CRONTAB')
  #Sidekiq::Cron::Job.destroy_all!
  #Sidekiq::Cron::Job.load_from_hash YAML.load_file(CRONTAB_FILE)
#end
