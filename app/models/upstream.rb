# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

# Собственно биржа.
#
# Например binance, peatio. Может быть даже псевдо-биржа, например, monolithos как источник данных0
#
# На бирже может быть несколько аккаунтов и несколько рынков (upstream_markets)
#
class Upstream
  extend Finders
  include RedisModel

  attr_reader :client_class, :markets

  def initialize(id:, client_class:, markets: nil)
    @client_class = client_class
    super id: id

    @markets = markets.nil? ? Market.all : markets.map { |market_id| Market.find! market_id }
  end

  def drainers
    @drainers ||= God.drainers.filter { |d| d.upstream == self }
  end

  def accounts
    Account.all.filter { |a| a.upstream == self }
  end

  def active_orders
    accounts.map(&:active_orders).flatten
  end

  def user_orders_volume(market:, side:)
    active_orders
      .filter { |o| o.market == market && o.side?(side) }
      .sum(&:remaining_volume)
  end

  def upstream_markets
    @upstream_markets ||=
      UpstreamMarkets
      .new(markets.map { |market| market.upstream_markets.find_by_upstream!(self) })
  end
end
