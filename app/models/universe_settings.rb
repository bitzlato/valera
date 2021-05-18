# frozen_string_literal: true

class UniverseSettings
  include RedisModel

  UNSCOPED_ATTRIBUTES = %i[id updated_at status stop_reason enabled].freeze

  INACTIVE_STATUS = :inactive
  ACTIVE_STATUS = :active
  INIT_STATUS = :init
  STATUSES = [INACTIVE_STATUS, ACTIVE_STATUS, INIT_STATUS].freeze

  # Manualy enable/disable
  attribute :enabled, Boolean, default: false
  attribute :status, Symbol, default: INIT_STATUS
  attribute :stop_reason, String

  validates :status, presence: true, inclusion: { in: STATUSES }

  def self.attributes_for_level(level)
    level = level.to_s
    attribute_set.map(&:name).select { |a| a.to_s.split('_').last == level }
  end

  def self.scope_attributes(scope)
    attribute_set.map(&:name).select { |k| k.to_s.starts_with? "#{scope}_" }
  end

  def self.model_name
    ActiveModel::Name.new(UniverseSettings)
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

  def stop!(reason)
    update_attributes! status: INACTIVE_STATUS, stop_reason: reason
  end

  def start!
    update_attributes! status: ACTIVE_STATUS, stop_reason: nil
  end

  def active?
    status == ACTIVE_STATUS
  end

  private

  def after_save
    UniverseChannel.update Universe.find id
  end
end
