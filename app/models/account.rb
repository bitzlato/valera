# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

# You account on upstream
#
class Account
  include RedisModel
  extend Finders

  attr_reader :upstream, :client

  attribute :balances, Hash
  attribute :balances_updated_at, Time
  attribute :active_orders, Array[PersistedOrder]
  attribute :active_orders_updated_at, Time
  attribute :day_trades_amounts, Hash # { market_id => amount }
  attribute :hour_trades_amounts, Hash # { market_id => amount }
  attribute :trades_updated_at, Time

  delegate :upstream_markets, to: :upstream

  def initialize(id:, upstream:, client: nil)
    super id: id
    @upstream = upstream
    @client = client
  end

  def markets
    upstream_markets.map(&:market).uniq
  end

  def update_active_orders!
    drainers.each { |d| d.update_active_orders! if d.respond_to? :update_active_orders! }
  end

  def brief
    if client.present?
      "#{self}:#{client.endpoint}"
    else
      to_s
    end
  end

  def trade_created(trade)
    strategies
      .filter { |s| s.market == trade.market }
      .each do |s|
      s.trade_created trade
    end
  end

  def strategies
    Strategy.all.filter { |s| s.account == self }
  end

  def drainers
    God.drainers.filter { |d| d.account == self }
  end

  def trades
    Trade.where(account_id: id)
  end

  def update_trades_amounts!
    update_attributes!(
      day_trades_amounts: trades_amounts_for(1.day.ago),
      hour_trades_amounts: trades_amounts_for(1.hour.ago),
      trades_updated_at: Time.now
    )
  end

  def trades_amounts_for(period)
    trades.where('traded_at>=?', period).group(:market_id).sum(:amount)
  end
end
