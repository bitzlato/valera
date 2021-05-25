# frozen_string_literal: true

class Trade < ApplicationRecord
  delegate :upstream, to: :account

  def market
    Market.find market_id
  end

  def account
    Account.find account_id
  end
end
