# frozen_string_literal: true

class TradeDecorator < ApplicationDecorator
  delegate_all

  def self.table_columns
    %i[trade_id side taker_type market account upstream amount price total]
  end

  def amount
    h.format_money object.amount, object.market.base
  end

  def price
    h.format_money object.price, object.market.base
  end

  def total
    h.format_money object.total, object.market.base
  end

  def market
    h.link_to object.market, h.market_path(object.market)
  end

  def account
    h.link_to object.account, h.account_path(object.account)
  end

  def upstream
    h.link_to object.upstream, h.upstream_path(object.upstream)
  end
end
