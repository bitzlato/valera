# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

module Valera
  class BaseClient
    Error = Class.new StandardError
    WrongResponse = Class.new Error
    Failure = Class.new Error
    InsufficientBalance = Class.new Error
    OrderCreationError = Class.new Error

    attr_reader :name, :endpoint

    def to_s
      "#{name}->#{endpoint}"
    end
  end
end
