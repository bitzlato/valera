# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

# Buyout order
#
class BuyoutOrder < ApplicationRecord
  include SideInquirer

  enum status: %i[initial posted waited ignored done]

  belongs_to :original_trade, class_name: 'Trade'

  delegate :base, :quote, to: :market

  def market
    @market ||= Market.find market_id
  end

  def revenue
    if side? :bid
      original_trade.total - volume_price
    else
      volume_price - original_trade.total
    end
  end

  def volume_price
    volume * price
  end

  def trade_account
    Account.find trade_account_id
  end

  def buyout_account
    Account.find buyout_account_id
  end
end
