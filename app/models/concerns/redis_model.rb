module RedisModel
  extend ActiveSupport::Concern
  included do
    attr_accessor :id
    alias_method :to_s, :id
    alias_method :to_param, :id
  end

  def persisted?
    true
  end

  def save!
    redis_value.value = as_json(except: 'id').to_json
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
    as_json(except: 'id').blank?
  end

  private

  def redis_value
    raise 'ID is not defined' if id.nil?
    Redis::Value.new([self.class.name,id].join(':'))
  end
end
