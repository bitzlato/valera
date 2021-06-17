# frozen_string_literal: true

class Trade < ApplicationRecord
  delegate :upstream, to: :account

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
