class UniverseSettings
  include RedisModel

  def self.defaults
    {}
  end

  def self.scope_attributes(scope)
    attribute_set.map(&:name).select { |k| k.to_s.starts_with? scope.to_s + '_' }
  end

  def self.model_name
    ActiveModel::Name.new(UniverseSettings)
  end
end
