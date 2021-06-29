# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class UpstreamMarket
  include RedisModel

  attribute :asksVolume, BigDecimal
  attribute :bidsVolume, BigDecimal
  attribute :usersAsksVolume, BigDecimal
  attribute :usersBidsVolume, BigDecimal

  # TODO: Remove existen attributes
  #
  Settings.upstream_keys.each do |key|
    attribute key, BigDecimal
  end

  attr_reader :market, :upstream

  def self.all
    Market.all.map { |m| m.upstream_markets.to_a }.flatten.uniq
  end

  def self.find_by(market:, account:)
    all.find { |um| um.upstream.accounts.include?(account) && um.market == market }
  end

  def self.find_by!(market:, account:)
    find_by(market: market, account: account) ||
      raise("No upstream market found for account:#{account} and market:#{market}")
  end

  def initialize(market:, upstream:)
    @market = market || raise('No market')
    @upstream = upstream || raise('No upstream')
    super id: [upstream, market.id].join(':')
  end

  def active_orders
    upstream
      .active_orders
      .filter { |o| o.market == market }
  end

  def my_orders_volume(side)
    active_orders
      .filter { |o| o.side? side }
      .sum(&:remaining_volume)
  end

  def to_hash
    super.merge avgPrice: avgPrice
  end

  def avgPrice # rubocop:disable Naming/MethodName
    return if askPrice.nil? || bidPrice.nil?

    (askPrice + bidPrice) / 2
  end

  private

  def update_users_volumes
    self.usersAsksVolume = calculate_user_orders_volume(:ask)
    self.usersBidsVolume = calculate_user_orders_volume(:bid)
  end

  def before_save
    update_users_volumes
    super
  end

  def calculate_user_orders_volume(side)
    total = send("#{side}sVolume")
    return if total.nil?
    return unless total.positive?

    volume = total - my_orders_volume(side)
    return unless volume.positive?

    volume
  end
end
