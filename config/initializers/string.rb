# frozen_string_literal: true

# Copyright (c) 2021 Danil Pismenny <danil@brandymint.ru>

class String
  def to_d_if_presence
    return nil if blank?

    to_d
  end
end

class NilClass
  def to_d_if_presence
    nil
  end
end
