# New state for processor
class UniverseState
  include ActiveModel::Model

  attr_accessor(*BinanceDrainer::KEYS)

  attr_accessor :id
  attr_accessor :peatio_quote_balance, :peatio_base_balance
  attr_accessor :last_orders

  alias_method :to_s, :id

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

  private

  def redis_value
    raise 'ID is not defined' if id.nil?
    Redis::Value.new(['universe_state',id].join(':'))
  end
end
