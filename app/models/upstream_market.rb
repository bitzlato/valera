# frozen_string_literal: true

class UpstreamMarket
  include RedisModel

  BASE_KEYS = %i[].freeze

  UPSTREAM_KEYS = (Settings.drainer_classes.map(&:keys).flatten + BASE_KEYS).uniq

  UPSTREAM_KEYS.each do |key|
    attribute key, BigDecimal
  end

  attr_reader :market, :upstream

  def self.find_or_create!(market:, upstream:)
    new(market: market, upstream: upstream).reload
  end

  def self.all
    Market.all.map(&:upstream_markets).flatten.uniq
  end

  def initialize(market:, upstream:)
    self.id = [upstream, market.id].join(':')
    @market = market || raise('No market')
    @upstream = upstream || raise('No upstream')
  end

  def to_hash
    super.merge avgPrice: avgPrice
  end

  def avgPrice # rubocop:disable Naming/MethodName
    return if askPrice.nil? || bidPrice.nil?

    (askPrice + bidPrice) / 2
  end

  private

  def after_save
    # market.notify_changes!
  end
end
