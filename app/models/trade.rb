# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class Trade < ApplicationRecord
  include SideInquirer

  delegate :upstream, to: :account
  delegate :base, :quote, to: :market, allow_nil: true

  has_one :buyout_order, foreign_key: :original_trade_id

  scope :today, -> { where 'traded_at>?', 24.hours.ago }

  after_commit on: :create do
    account.trade_created self
  end

  def market
    @market ||= Market.find market_id
  end

  def market=(new_market)
    self.market_id = new_market.id
  end

  def account
    @account ||= Account.find account_id
  end
end
