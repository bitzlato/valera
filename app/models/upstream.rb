# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class Upstream
  extend Finders
  include RedisModel

  attr_reader :client_class

  Market.all.each do |market|
    # А где они используютcя?
    attribute "bid_orders_volume_#{market.variable_name}", BigDecimal
    attribute "ask_orders_volume_#{market.variable_name}", BigDecimal
  end

  def initialize(id:, client_class:)
    @client_class = client_class
    super id: id
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

  # TODO: List only using makets
  #
  def markets
    @markets ||= Market.all
  end

  def upstream_markets
    @upstream_markets ||=
      UpstreamMarkets
      .new(markets.map { |market| market.upstream_markets.find_by_upstream!(self) })
  end
end
