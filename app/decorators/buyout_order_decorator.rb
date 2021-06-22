# frozen_string_literal: true

class BuyoutOrderDecorator < ApplicationDecorator
  delegate_all
  def self.table_columns
    %i[id created_at updated_at market trade_account buyout_account orders status ignore_message]
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
