# frozen_string_literal: true

module RedisModel
  VERSION = 3

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

    def self.find_or_create!(id, _default_settings = {})
      new(id: id).reload
    end

    def self.attribute_names
      attribute_set.map(&:name)
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
    redis_value.value = attributes.except(:id)
    after_save
    self
  end

  def reload
    if persisted?
      begin
        restore!
        validate!
      rescue ActiveModel::ValidationError, ActiveModel::UnknownAttributeError => e
        Rails.logger.error "#{e} restoring #{self}##{id}, reset to defaults"
        clear!
      end
    else
      clear!
    end

    self
  end

  def clear!
    binding.pry
    set_default_attributes!
    validate!
    save!
  end

  def blank?
    attributes.except(:id).blank?
  end

  private

  def restore!
    assign_attributes redis_value.value if persisted?
  end

  def after_save; end

  def redis_value
    raise 'ID is not defined' if id.nil?

    @redis_value ||= Redis::Value.new( redis_value_id, marshal: true)
  end

  def redis_value_id
    [VERSION, self.class.name, id].join(':')
  end
end
