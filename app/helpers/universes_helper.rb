module UniversesHelper
  def universe_settings_attribute_input(settings, attribute)
    display_with = ->(value) { format_percent value } if attribute.to_s.include? 'threshold'
    best_in_place settings, attribute, as: :input, display_with: display_with
  end
end
