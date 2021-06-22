# Buyout order
#
class BuyoutOrder < ApplicationRecord
  include SideInquirer

  enum status: %i[initial posted waited done]

  belongs_to :original_trade, class_name: 'Trade'

  def market
    @market ||= Market.find market_id
  end

  def revenue
    original_trade.total - volume_price
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
