# frozen_string_literal: true

module StrategiesHelper
  PERCENTAGE_SUFFIXES = %w[_threshold _deviation _part].freeze

  def strategy_settings_attribute_input(strategy, attribute)
    side = attribute.to_s.split('_').first
    currency_method = side == 'bid' ? :quote : :base
    if PERCENTAGE_SUFFIXES.find { |suffix| attribute.to_s.include? suffix }
      display_with = lambda { |value|
        format_percent value
      }
    end
    if attribute.to_s.include? '_volume'
      display_with = lambda { |value|
        format_money value, strategy.market.send(currency_method)
      }
    elsif attribute.to_s.include? 'latency'
      display_with = ->(value) { "#{value} sec" }
    end
    type = attribute.to_s.include?('enabled') ? :checkbox : :input
    collection = %w[Disabled Enabled] if attribute.to_s == 'enabled'
    best_in_place strategy.settings, attribute, as: type, display_with: display_with, collection: collection
  end

  STATUS_LABELS = {
    true => 'badge-success',
    false => 'badge-warning',
    idle: 'badge-info'
  }.freeze

  def strategy_status(strategy)
    state = strategy.state.is_active
    title = strategy.state.is_active? ? 'active' : 'inactive'
    if state && !strategy.settings.enabled?
      state = :idle
      title = 'idle'
    end
    buffer = content_tag :span, title, class: "badge #{STATUS_LABELS[state]}"

    unless strategy.state.is_active
      buffer << content_tag(:div,
                            strategy.state.inactivation_reason.presence || 'No inactivation reason',
                            class: 'mt-2 alert alert-warning')
    end
    buffer.html_safe
  end

  def default_settings_attribute(attribute)
    attribute = attribute.to_s
    return attribute unless attribute.include? '_'

    title = attribute.split('_').slice(1, 100).join('_')
    title = title.split('_').slice(0, title.split('_').length - 1).join('_') if leveled_attribute?(attribute)
    title
  end

  def leveled_attribute?(attribute)
    attribute.to_s.split('_').last.to_i.to_s == attribute.to_s.split('_').last
  end
end