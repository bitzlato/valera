# frozen_string_literal: true

class Float
  def percent_of(value)
    to_d.percent_of value
  end
end
