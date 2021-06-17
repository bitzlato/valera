class BuyoutOrder < ApplicationRecord
  enum status: %i[initial posted waited done]

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

  def original_trade
    Trade.find original_trade_id
  end

  def target_account
    Account.find target_account_id
  end
end
