# frozen_string_literal: true

# Redis#exists(key)` will return an Integer in redis-rb 4.3. `exists?` returns a boolean, you should use it instead. To opt-in to the new behavior now you can set Redis.exists_returns_integer =  true. To disable this message and keep the current (boolean) behaviour of 'exists' you can set `Redis.exists_returns_integer = false`, but this option will be removed in 5.0. (/home/danil/.rbenv/versions/2.7.2/lib/ruby/gems/2.7.0/gems/sidekiq-cron-1.2.0/lib/sidekiq/cron/job.rb:464:in `block in save
Redis.exists_returns_integer = true
require 'sidekiq'
Sidekiq.default_worker_options = { 'backtrace' => true }

if ENV.true?('SIDEKIQ_INLINE')
  puts 'Sidekiq inline'
  require 'sidekiq/testing/inline'
  Sidekiq::Testing.inline!

elsif Rails.env.production? || Rails.env.staging? || Rails.env.development?
  Sidekiq.options[:poll_interval] = 1

  Sidekiq.logger = ActiveSupport::Logger.new Rails.root.join './log/sidekiq.log'
  Sidekiq.configure_server do |config|
    config.redis =  { :url => ENV.fetch('VALERA_SIDEKIQ_REDIS_URL', 'redis://localhost:6379/4') }
    config.error_handlers << proc do |ex, context|
      Bugsnag.notify ex do |b|
        b.meta_data = context
      end
    end
    Sidekiq.logger.info "Configure server for application #{AppVersion}"
  end

  Sidekiq.configure_client do |config|
    config.redis = { :url => ENV.fetch('VALERA_SIDEKIQ_REDIS_URL', 'redis://localhost:6379/4') }
    Sidekiq.logger.info "Configure server for application #{AppVersion}"
  end
elsif Rails.env.test?
  require 'sidekiq/testing/inline'
  Sidekiq::Testing.fake!
else
  raise "Not supported env #{Rails.env}"
end


CRONTAB_FILE = './config/sidekiq_crontab.yml'

if Rails.env.staging? || Rails.env.production? || ENV.true?('LOAD_SIDEKIQ_CRONTAB')
  Sidekiq::Cron::Job.destroy_all!
  Sidekiq::Cron::Job.load_from_hash YAML.load_file(CRONTAB_FILE)
end
