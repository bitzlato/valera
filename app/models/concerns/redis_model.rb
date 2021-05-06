module RedisModel
  extend ActiveSupport::Concern
  included do
    include Virtus.model
    include ActiveModel::AttributeAssignment
    include ActiveModel::Validations
    include ActiveModel::Conversion

    attribute :id, String

    alias_method :to_s, :id
    alias_method :to_param, :id

    def self.find_or_build(id, default_settings = {})
      record = new(id: id)
      record.restore!
      if record.blank?
        record.assign_attributes default_settings
        raise "Invalid default settings #{default_settings} for #{self}" unless valid?
      end
      record
    end
  end

  def update_attributes(attributes)
    assign_attributes attributes
    save! if valid?
  end

  def persisted?
    true
  end

  def save!
    redis_value.value = attributes.except(:id).to_json
  end

  def restore!
    value = redis_value.value
    assign_attributes JSON.parse(value) if value.present?
  end

  def clear!
    redis_value.delete
    instance_variables.reject { |a| a == :@id }.each { |var| remove_instance_variable var }
  end

  def blank?
    attributes.except(:id).blank?
  end

  #def attributes
    #as_json(except: ['id', 'errors'])
  #end

  private

  def redis_value
    raise 'ID is not defined' if id.nil?
    @redis_value ||= Redis::Value.new([self.class.name,id].join(':'))
  end
end
