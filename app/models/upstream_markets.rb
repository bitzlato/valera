# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class UpstreamMarkets < Set
  NotFound = Class.new StandardError

  def find_by_upstream!(upstream)
    find do |u|
      upstream.is_a?(Upstream) ? u.upstream == upstream : u.upstream.id == upstream.to_s
    end || raise(NotFound, "No #{upstream} upstream market found")
  end

  def find_by_market!(market)
    find do |u|
      market.is_a?(Market) ? u.market == market : u.market.id == market.to_s
    end || raise(NotFound, "No #{market} upstream market found")
  end
end
