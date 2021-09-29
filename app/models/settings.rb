# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

require 'settingslogic'
class Settings < Settingslogic
  DIR = Rails.root.join('config', 'settings', Rails.env)

  source Rails.root.join('config', 'settings.yml')
  namespace Rails.env
  suppress_errors Rails.env.production?

  class Drainers < Settingslogic
    source DIR.join('drainers.yml')
    suppress_errors Rails.env.production?

    def upstream_keys
      drainer_classes.select { |d| d.respond_to?(:keys) }.map(&:keys).flatten.uniq
    end

    private

    def drainer_classes
      self.class.drainers.values.map do |v|
        v['class'].constantize
      end.uniq
    end
  end

  class Upstreams < Settingslogic
    source DIR.join('upstreams.yml')
    suppress_errors Rails.env.production?
  end

  class Markets < Settingslogic
    source DIR.join('markets.yml')
    suppress_errors Rails.env.production?
  end

  class Accounts < Settingslogic
    source DIR.join('accounts.yml')
    suppress_errors Rails.env.production?
  end

  class Strategies < Settingslogic
    source DIR.join('strategies.yml')
    suppress_errors Rails.env.production?
  end
end
