# frozen_string_literal: true

class UpstreamMarkets < Set
  def find_by_upstream!(upstream)
    find do |u|
      upstream.is_a?(Upstream) ? u.upstream == upstream : u.upstream.id == upstream.to_s
    end || raise("No #{upstream} upstream market found")
  end
end
