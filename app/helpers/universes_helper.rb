# frozen_string_literal: true

module UniversesHelper
  def universe_settings_attribute_input(universe, attribute)
    side = attribute.to_s.split('_').first
    currency_method = side == 'bid' ? :quote : :base
    display_with = ->(value) { format_percent value } if attribute.to_s.include? '_threshold'
    if attribute.to_s.include? '_volume'
      display_with = lambda { |value|
        format_money value, universe.market.send(currency_method)
      }
    end
    best_in_place universe.settings, attribute, as: :input, display_with: display_with
  end
end
