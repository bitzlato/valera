# frozen_string_literal: true

module UniversesHelper
  def universe_settings_attribute_input(universe, attribute)
    side = attribute.to_s.split('_').first
    currency_method = side == 'bid' ? :quote : :base
    display_with = ->(value) { format_percent value } if attribute.to_s.include?('_threshold') || attribute.to_s.include?('_deviation') || attribute.to_s.include?('_part')
    if attribute.to_s.include? '_volume'
      display_with = lambda { |value|
        format_money value, universe.market.send(currency_method)
      }
    end
    type = attribute.to_s.include?('enabled') ? :checkbox : :input
    collection = ['Disabled', 'Enabled'] if attribute.to_s == 'enabled'
    best_in_place universe.settings, attribute, as: type, display_with: display_with, collection: collection
  end

  STATUS_LABELS = {
    init: 'badge-info',
    active: 'badge-success',
    inactive: 'badge-warning'
  }.freeze

  def universe_status(universe)
    buffer = content_tag :span, class: "badge #{STATUS_LABELS[universe.settings.status]}" do
      universe.settings.status.to_s
    end

    if universe.settings.status == UniverseSettings::INACTIVE_STATUS
      buffer << content_tag(:div,
                            universe.settings.stop_reason)
    end
    buffer.html_safe
  end

  def default_settings_attribute(attribute)
    attribute = attribute.to_s
    return attribute unless attribute.include? '_'
    title = attribute.split('_').slice(1,100).join('_')
    title = title.split('_').slice(0,title.split('_').length - 1).join('_') if leveled_attribute?(attribute)
    title
  end

  def leveled_attribute?(attribute)
    attribute.to_s.split('_').last.to_i.to_s == attribute.to_s.split('_').last
  end
end
