# New state for processor
class InputData
  include ActiveModel::Model

  attr_accessor(*BinanceDrainer::KEYS)

  alias_method :to_s, :to_json
end
