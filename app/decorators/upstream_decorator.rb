# frozen_string_literal: true

class UpstreamDecorator < ApplicationDecorator
  delegate_all

  def self.table_columns
    %i[id markets accounts upstream_markets]
  end

  def accounts
    object.accounts.map do |account|
      h.link_to account, h.account_path(account)
    end.join(', ').html_safe
  end

  def markets
    object.markets.map do |market|
      h.link_to market, h.market_path(market)
    end.join(', ').html_safe
  end

  def upstream_markets
    object.upstream_markets.map do |um|
      h.link_to um, h.upstream_market_path(um)
    end.join(', ').html_safe
  end
end
