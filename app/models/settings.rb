# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

require 'settingslogic'
if defined? Rails
  class Settings < Settingslogic
    source Rails.root.join('config', 'settings.yml')
    source Rails.root.join('config', 'settings.local.yml')
    namespace Rails.env
    suppress_errors Rails.env.production?
  end
else
  class Settings < Settingslogic
    source './config/settings.yml'
    source './config/settings.local.yml'
    namespace 'development'
  end
end

class Settings
  def drainer_classes
    Settings.drainers.values.map do |v|
      v['class'].constantize
    end.uniq
  end

  def upstream_keys
    drainer_classes.select { |d| d.respond_to?(:keys) }.map(&:keys).flatten.uniq
  end
end
