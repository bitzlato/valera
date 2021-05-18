# frozen_string_literal: true

# Periodicaly fetch data from upstream and save it in MarketUpsteamState
#
class PeatioBalanceDrainer < Drainer
  FETCH_PERIOD = 1 # sec

  KEYS = %i[balance].freeze

  def attach
    logger.info("Add periotic timer for #{FETCH_PERIOD} sec")
    EM.add_periodic_timer FETCH_PERIOD do
      update!
    end
  end


  def update!
    fetch_and_update_balances!
  end

  private

  def fetch_and_update_balances!
    balances = account
      .client
      .account_balances
      .each_with_object(ActiveSupport::HashWithIndifferentAccess.new) { |r, a| a[r['currency']]=r['balance'] }
    account.update_attributes! balances: balances
  end

  def fetch_and_update_market_depth!
    Async do
      update_market_depth! client.market_depth market.peatio_symbol
    end
  end
end
