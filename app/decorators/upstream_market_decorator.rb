# frozen_string_literal: true

class UpstreamMarketDecorator < ApplicationDecorator
  delegate_all

  def self.table_columns
    super + %i[market upstream strategies]
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
