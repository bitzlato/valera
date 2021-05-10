class UniverseSettings
  include RedisModel
  SCOPES = %i[base ask bid]

  def scopes
    self.class.const_get :SCOPES
  end

  def self.scope_attributes(scope)
    attribute_set.map(&:name).select { |k| k.to_s.starts_with? "#{scope}_" }
  end

  def self.model_name
    ActiveModel::Name.new(UniverseSettings)
  end
end
