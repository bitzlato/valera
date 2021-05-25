class Trade < ApplicationRecord
  def market
    Market.find market_id
  end

  def upstream
    Upstream.find upstream_id
  end

  def account
    Account.find account_id
  end
end
