module Valera
  class BaseClient
    Error = Class.new StandardError
    WrongResponse = Class.new Error
    Failure = Class.new Error
    InffuccientBalance = Class.new
  end
end
