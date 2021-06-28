# frozen_string_literal: true

module Valera
  class BaseClient
    Error = Class.new StandardError
    WrongResponse = Class.new Error
    Failure = Class.new Error
    InffuccientBalance = Class.new

    attr_reader :name, :endpoint

    def to_s
      "#{name}->#{endpoint}"
    end
  end
end
