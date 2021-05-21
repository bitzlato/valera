# frozen_string_literal: true

class StrategySettings
  include RedisModel

  UNSCOPED_ATTRIBUTES = %i[id updated_at enabled].freeze

  # Manualy enable/disable
  attribute :enabled, Boolean, default: false

  # Latency to update. Required to not update too often (seconds)
  attribute :latency, BigDecimal, default: 0.3

  def self.attributes_for_level(level)
    level = level.to_s
    attribute_set.map(&:name).select { |a| a.to_s.split('_').last == level }
  end

  def self.scope_attributes(scope)
    attribute_set.map(&:name).select { |k| k.to_s.starts_with? "#{scope}_" }
  end

  def self.model_name
    ActiveModel::Name.new(StrategySettings)
  end

  def leveled_attributes_unsuffixed
    attributes
      .keys
      .select { |a| a.to_s.split('_').last.to_i.to_s == a.to_s.split('_').last }
      .map { |a| a.to_s.split('_')[0...-1].join('_') }
      .uniq
  end

  def levels
    0
  end

  def scopes
    attribute_set
      .map(&:name)
      .reject { |i| UNSCOPED_ATTRIBUTES.include? i }
      .map { |i| i.to_s.split('_').first }
      .uniq
      .map(&:to_sym)
  end

  private

  def after_save
    StrategyChannel.update Strategy.find id
  end
end
