# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

require_relative 'boot'
ENV['RANSACK_FORM_BUILDER'] = '::SimpleForm::FormBuilder'
require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module Exbot
  class Application < Rails::Application
    config.action_cable.mount_path = '/valera/cableFAKE'

    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 6.1
    config.i18n.default_locale = :ru

    config.generators do |g|
      g.template_engine :slim
    end

    config.autoload_paths += Dir[
      "#{Rails.root}/app/services",
      "#{Rails.root}/app/drainers",
      "#{Rails.root}/app/inputs",
      "#{Rails.root}/app/strategies",
    ]

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    config.time_zone = 'Moscow'
    # config.eager_load_paths << Rails.root.join("extras")
  end
end
