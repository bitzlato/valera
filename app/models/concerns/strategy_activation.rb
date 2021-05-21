module StrategyActivation
  extend ActiveSupport::Concern
  included do
    attribute :is_active, Virtus::Attribute::Boolean, default: false
    attribute :inactivation_reason, String, default: 'Never run'
    attribute :inactivated_at, Time
    attribute :activated_at, Time
  end

  def stop!(reason)
    update_attributes! is_active: false, inactivation_reason: reason, inactivated_at: Time.zone.now
  end

  def start!
    update_attributes! is_active: true, inactivation_reason: nil, activated_at: Time.zone.now, maker_pid: Process.pid
  end
end
