# Buyout order
#
class BuyoutOrder < ApplicationRecord
  enum status: %i[initial posted waited done]

  belongs_to :original_trade, class_name: 'Trade'

  def market
    @market ||= Market.find market_id
  end

  def revenue
    original_trade.value_price - value_price
  end

  def volume_price
    volume * price
  end

  def trade_account
    Account.find trade_account_id
  end

  def target_account
    Account.find target_account_id
  end
end
