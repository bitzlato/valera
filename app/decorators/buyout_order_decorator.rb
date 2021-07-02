# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class BuyoutOrderDecorator < ApplicationDecorator
  delegate_all

  def self.table_columns
    %i[id created_at side market trade_account buyout_account orders status ignore_message meta]
  end

  def self.table_td_class(column)
    css_class = super(column).to_s.dup
    css_class << ' p-0' if column.to_s == 'orders'
    css_class
  end

  def ignore_message
    return '' if object.ignore_message.blank?

    h.content_tag :em do
      object.ignore_message.truncate(80)
    end
  end

  def status
    h.buyout_order_status object
  end

  def orders
    h.render 'buyout_orders/orders', buyout_order: object
  end

  def volume
    h.format_money object.volume, object.market.base
  end

  def price
    h.format_money object.price, object.market.quote
  end

  def total
    h.format_money object.volume_price, object.market.quote
  end

  def revenue
    h.format_money object.revenue, object.market.quote
  end

  def original_trade
    h.render 'trade_brief', trade: object.original_trade
  end
end
