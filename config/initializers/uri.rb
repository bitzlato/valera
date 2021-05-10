# frozen_string_literal: true

module URI2
  def self.unescape(args)
    URI.decode args
  end
end
