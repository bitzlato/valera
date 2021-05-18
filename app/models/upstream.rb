# frozen_string_literal: true

class Upstream
  include RedisModel

  def self.all
    God.upstreams
  end

  attr_reader :drainers

  def initialize(id, config = {})
    super id: id
    @drainers = config
  end

  # TODO: List only using makets
  #
  def markets
    @markets ||= Market.all
  end

  def upstream_markets
    @upstream_markets ||= UpstreamMarkets.new(
      markets.map { |market| market.upstream_markets[self] }
    )
  end
end
