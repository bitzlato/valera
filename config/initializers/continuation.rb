# Source: https://www.honeybadger.io/blog/how-to-try-again-when-exceptions-happen-in-ruby/
#
require "continuation"
class Exception
  attr_accessor :continuation
  def skip
    continuation.call
  end
end

module StoreContinuationOnRaise
  def raise(*args)
    callcc do |continuation|
      begin
        super
      rescue Exception => e
        e.continuation = continuation
        super(e)
      end
    end
  end
end

class Object
  include StoreContinuationOnRaise
end
