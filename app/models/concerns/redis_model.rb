# frozen_string_literal: true

module RedisModel
  extend ActiveSupport::Concern
  included do
    include Virtus.model
    include ActiveModel::AttributeAssignment
    include ActiveModel::Validations
    include ActiveModel::Conversion

    attribute :id, String
    attribute :updated_at, Time

    alias_method :to_s, :id
    alias_method :to_param, :id

    def self.find_or_build(id, default_settings = {})
      record = new(id: id)
      if record.persisted?
        record.safe_restore!
      else
        record.update_attributes! default_settings
      end
      record
    end
  end

  def update_attributes(attributes)
    update_attributes!(attributes)
    true
  rescue ActiveModel::ValidationError
    false
  end

  def update_attributes!(attributes)
    assign_attributes attributes
    save!
  end

  def persisted?
    redis_value.value.present?
  end

  def save!
    validate!
    self.updated_at = Time.zone.now
    redis_value.value = attributes.except(:id).to_json
    after_save
  end

  def safe_restore!
    restore!
    validate!
  rescue ActiveModel::ValidationError, ActiveModel::UnknownAttributeError => e
    Rails.logger.error "#{e} restoring #{self}##{id}, reset to defaults"
    clear_attributes!
    set_default_attributes!
    save!
  end

  def restore!
    assign_attributes JSON.parse(redis_value.value) if persisted?
  end

  def clear!
    redis_value.delete
    clear_attributes!
    set_default_attributes!
  end

  def blank?
    attributes.except(:id).blank?
  end

  private

  def after_save
  end

  def clear_attributes!
    instance_variables.reject { |a| a == :@id }.each { |var| remove_instance_variable var }
  end

  def redis_value
    raise 'ID is not defined' if id.nil?

    @redis_value ||= Redis::Value.new([self.class.name, id].join(':'))
  end
end
