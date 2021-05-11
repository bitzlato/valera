# frozen_string_literal: true

class UniverseSettings
  include RedisModel

  UNSCOPED_ATTRIBUTES = %i[id updated_at status stop_reason]

  INACTIVE_STATUS = :inactive
  ACTIVE_STATUS= :active
  INIT_STATUS = :init
  STATUSES = [INIT_STATUS, ACTIVE_STATUS, INIT_STATUS]

  # Manualy enable/disable
  attribute :base_enabled, Boolean, default: false
  attribute :status, Symbol, default: INIT_STATUS
  attribute :stop_reason, String

  validates :status, presence: true, inclusion: { in: STATUSES }

  def scopes
    attribute_set.map(&:name).reject { |i| UNSCOPED_ATTRIBUTES.include? i }.map { |i| i.to_s.split('_').first }.uniq.map &:to_sym
  end

  def stop!(reason)
    update_attributes! status: UniverseSettings::INACTIVE_STATUS, stop_reason: reason
  end

  def start!
    update_attributes! status: UniverseSettings::ACTIVE_STATUS, stop_reason: nil
  end

  def self.scope_attributes(scope)
    attribute_set.map(&:name).select { |k| k.to_s.starts_with? "#{scope}_" }
  end

  def self.model_name
    ActiveModel::Name.new(UniverseSettings)
  end

  private

  def after_save
    UniverseChannel.update Universe.find id
  end
end
