# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class UpstreamMarketDecorator < ApplicationDecorator
  delegate_all

  def self.table_columns
    %i[market upstream strategies active_orders_count my_asks_orders_volume my_bids_orders_volume] + super
  end

  def active_orders_count
    active_orders.count
  end

  def my_asks_orders_volume
    my_orders_volume(:ask)
  end

  def my_bids_orders_volume
    my_orders_volume(:bid)
  end

  def market
    h.link_to object.market, h.market_path(object.market.id)
  end

  # We need to define it because of open-url method received
  def open
    object.open
  end

  def strategies
    object.market.strategies.map do |u|
      h.link_to u.class_and_name, h.strategy_path(u)
    end.join(', ').html_safe
  end
end
