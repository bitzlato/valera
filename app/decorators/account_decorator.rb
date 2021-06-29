# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class AccountDecorator < ApplicationDecorator
  delegate_all

  def self.table_columns
    %i[id updated_at drainers upstream client balances active_orders trades_updated_at trades day_trades_amounts
       hour_trades_amounts]
  end

  def drainers
    object.drainers.map do |drainer|
      h.link_to drainer.to_s, h.drainer_path(drainer.id || :unknown)
    end.join(', ').html_safe
  end

  def active_orders
    h.render 'accounts/active_orders', account: object
  end

  def balances(currencies = nil)
    h.render 'balances', account: object, currencies: currencies
  end

  def trades
    h.link_to object.trades.count, h.trades_path(q: { account_id_eq: object.id })
  end

  def trades_updated_at
    present_time object.trades_updated_at
  end

  def upstream
    h.link_to object.upstream, h.upstream_path(object.upstream)
  end

  def client
    return h.middot if object.client.nil?

    object.client.to_s
  end

  def day_trades_amounts
    h.render 'trades_amounts', amounts: object.day_trades_amounts, account: object, time_ago: 1.day.ago
  end

  def hour_trades_amounts
    h.render 'trades_amounts', amounts: object.hour_trades_amounts, account: object, time_ago: 1.hour.ago
  end
end
