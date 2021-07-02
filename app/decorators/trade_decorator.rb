# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class TradeDecorator < ApplicationDecorator
  delegate_all

  def self.table_columns
    %i[trade_id traded_at side taker_type market account upstream amount price total]
  end

  def amount
    h.format_money object.amount, object.market.base
  end

  def price
    h.format_money object.price, object.market.quote
  end

  def total
    h.format_money object.total, object.market.quote
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

  def buyout_brief
    if object.buyout_order.present?
      h.render 'buyout_brief', buyout_order: buyout_order
    else
      h.middot
    end
  end
end
