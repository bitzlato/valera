
# frozen_string_literal: true

class UpstreamMarket
  include RedisModel

  BASE_KEYS = %i[base_balance quote_balance]

  UPSTREAM_KEYS = (Settings.drainers.map(&:keys).flatten + BASE_KEYS).uniq

  UPSTREAMS = Settings.upstreams.keys
  UPSTREAMS.each do |upstream|
    UPSTREAM_KEYS.each do |key|
      attribute key, BigDecimal
    end
  end

  attr_reader :market, :upstream

  def self.find_or_create!(market: , upstream: )
    new(market: market, upstream: upstream).reload
  end

  def self.all
    Market.all.map { |m| m.upstream_states.values }.flatten.uniq
  end

  def initialize(market:, upstream: )
    self.id = [upstream, market.id].join(':')
    @market = market || raise("No market")
    @upstream = upstream || raise("No upstream")
  end

  def to_hash
    super.merge avgPrice: avgPrice
  end

  def avgPrice
    return if askPrice.nil? || bidPrice.nil?

    (askPrice + bidPrice) / 2
  end

  private

  def after_save
    market.notify_changes!
  end
end
