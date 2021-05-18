# frozen_string_literal: true

# Periodicaly fetch data from upstream and save it in MarketUpsteamState
#
class PeatioBalanceDrainer < Drainer
  FETCH_PERIOD = 1 # sec

  KEYS = %i[balance].freeze

  def attach
    logger.info("Add periotic timer for #{FETCH_PERIOD} sec")
    EM.add_periodic_timer FETCH_PERIOD do # sec
      logger.debug('Timer executed')
      # fetch_and_update_balances!
    end
  end

  private

  def fetch_and_update_balances!
    accounts.each do |peatio_client|
      balances = peatio_client.account_balances
      state = market.upstream_account_state(upstream)
      state.assign_attributes(
        peatio_base_balance: find_balance(balances, market.base.downcase),
        peatio_quote_balance: find_balance(balances, market.quote.downcase)
      )
    end
  end

  def fetch_and_update_market_depth!
    Async do
      update_market_depth! client.market_depth market.peatio_symbol
    end
  end
end
