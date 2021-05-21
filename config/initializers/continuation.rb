# frozen_string_literal: true

# Source: https://www.honeybadger.io/blog/how-to-try-again-when-exceptions-happen-in-ruby/
#
require 'continuation'
class Exception
  attr_accessor :continuation

  def skip
    continuation.try :call
  end
end

module StoreContinuationOnRaise
  def raise(*args)
    callcc do |continuation|
      super
    rescue Exception => e # rubocop:disable Lint/RescueException
      e.continuation = continuation
      super(e)
    end
  end
end

class Object
  include StoreContinuationOnRaise
end
