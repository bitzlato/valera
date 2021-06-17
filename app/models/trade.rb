# frozen_string_literal: true

class Trade < ApplicationRecord
  delegate :upstream, to: :account

  has_one :buyout_order, foreign_key: :original_trade_id

  after_commit on: :create do
    account.trade_created self
  end

  def market
    @market ||= Market.find market_id
  end

  def account
    @account ||= Account.find account_id
  end
end
