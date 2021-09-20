# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

source 'https://rubygems.org'
git_source(:github) { |repo| "https://github.com/#{repo}.git" }

ruby File.read('.ruby-version')

gem 'slim-rails'
# Bundle edge Rails instead: gem 'rails', github: 'rails/rails'
gem 'rails', '~> 6.1.1'
# Use postgresql as the database for Active Record
gem 'pg', '~> 1.1'
# Use Puma as the app server
gem 'puma', '~> 5.0'
# Use SCSS for stylesheets
gem 'sass-rails', '>= 6'
# Transpile app-like JavaScript. Read more: https://github.com/rails/webpacker
gem 'webpacker', '~> 5.0'
# Turbolinks makes navigating your web application faster. Read more: https://github.com/turbolinks/turbolinks
gem 'turbolinks', '~> 5'
# Build JSON APIs with ease. Read more: https://github.com/rails/jbuilder
gem 'jbuilder', '~> 2.7'
# Use Redis adapter to run Action Cable in production
# gem 'redis', '~> 4.0'
# Use Active Model has_secure_password
# gem 'bcrypt', '~> 3.1.7'

# Use Active Storage variant
# gem 'image_processing', '~> 1.2'

# Reduces boot times through caching; required in config/boot.rb
gem 'active_link_to'
gem 'bootsnap', '>= 1.4.4', require: false
gem 'connection_pool'
gem 'draper'
gem 'env-tweaks', '~> 1.0.0'

gem 'ransack'
gem 'simple_form'

# Alternative: https://github.com/soveran/ohm
gem 'redis-objects'

gem 'rails-i18n'

gem 'jwt', github: 'jwt/ruby-jwt'
gem 'jwt-multisig', '~> 1.0.0'
gem 'jwt-rack', '~> 0.1.0', require: false
gem 'parallel'
gem 'safe_yaml', '~> 1.0.5', require: 'safe_yaml/load'
gem 'semver2'
gem 'settingslogic'

group :development, :test do
  gem 'foreman'
  gem 'pry'
  gem 'pry-byebug'
  gem 'pry-rails'
  gem 'scss-lint'
  # Call 'byebug' anywhere in the code to stop execution and get a debugger console
  gem 'byebug', platforms: %i[mri mingw x64_mingw]
  gem 'guard'
  gem 'guard-minitest'
  gem 'guard-rubocop'
  gem 'guard-shell'
  gem 'rubocop-rails'
end

group :development do
  # Access an interactive console on exception pages or by calling 'console' anywhere in the code.
  gem 'web-console', '>= 4.1.0'
  # Display performance information such as SQL time and flame graphs for each request in your browser.
  # Can be configured to work on production as well see: https://github.com/MiniProfiler/rack-mini-profiler/blob/master/README.md
  gem 'listen', '~> 3.3'
  gem 'rack-mini-profiler', '~> 2.0'
  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring
  gem 'spring'
end

group :test do
  # Adds support for Capybara system testing and selenium driver
  gem 'capybara', '>= 3.26'
  gem 'selenium-webdriver'
  # Easy installation and use of web drivers to run system tests with browsers
  gem 'minitest-around'
  gem 'minitest-focus'
  gem 'ruby-prof'
  gem 'vcr'
  gem 'webdrivers'
  gem 'webmock', '~> 3.5'
end

# Windows does not include zoneinfo files, so bundle the tzinfo-data gem
gem 'tzinfo-data', platforms: %i[mingw mswin x64_mingw jruby]

gem 'nokogiri', '~> 1.11'

gem 'auto_logger', github: 'BrandyMint/auto_logger'

gem 'binance', '~> 1.2', github: 'finfex/binance', branch: 'immutable-strings-ruby-27'

gem 'eventmachine'

gem 'money', '~> 6.14'

gem 'influxdb', '~> 0.8.1'

gem 'bugsnag'

gem 'technical-analysis', '~> 0.2.4'

gem 'best_in_place', git: 'https://github.com/mmotherwell/best_in_place'

gem 'sd_notify'
gem 'virtus', '~> 1.0'

gem 'sqlite3'

# gem 'peatio_client', '~> 0.0.7'

# gem 'async-http-faraday', '~> 0.9.0'

gem 'kaminari', '~> 1.2'

gem 'dotenv-rails', '~> 2.7'

gem 'percentage', '~> 1.4'

gem 'mini_racer', '~> 0.4.0'
group :deploy do
  gem 'bugsnag-capistrano', require: false
  gem 'capistrano', require: false
  gem 'capistrano3-puma'
  gem 'capistrano-bundler', require: false
  gem 'capistrano-db-tasks', require: false
  gem 'capistrano-dotenv-tasks'
  gem 'capistrano-faster-assets', require: false
  gem 'capistrano-git-with-submodules'
  gem 'capistrano-master-key', require: false, github: 'virgoproz/capistrano-master-key'
  gem 'capistrano-nvm', require: false
  gem 'capistrano-rails', require: false
  gem 'capistrano-rails-console', require: false
  gem 'capistrano-rbenv', require: false
  gem 'capistrano-shell', require: false
  gem 'capistrano-systemd-multiservice', github: 'groovenauts/capistrano-systemd-multiservice', require: false
  gem 'capistrano-yarn', require: false
end
