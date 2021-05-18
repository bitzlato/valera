# frozen_string_literal: true

class UpstreamMarket
  include RedisModel

  Settings.upstream_keys.each do |key|
    attribute key, BigDecimal
  end

  attr_reader :market, :upstream

  def self.all
    Market.all.map { |m| m.upstream_markets.to_a }.flatten.uniq
  end

  def initialize(market:, upstream:)
    @market = market || raise('No market')
    @upstream = upstream || raise('No upstream')
    super id: [upstream, market.id].join(':')
  end

  def to_hash
    super.merge avgPrice: avgPrice
  end

  def avgPrice # rubocop:disable Naming/MethodName
    return if askPrice.nil? || bidPrice.nil?

    (askPrice + bidPrice) / 2
  end
end
