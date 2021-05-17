class UpstreamMarkets < Set
  def find_by_upstream!(upstream)
    find { |u| upstream.is_a?(Upstream) ? u.upstream == upstream : u.upstream.id == upstream.to_s } ||
      raise("No #{upstream} upstream market found")
  end
end
