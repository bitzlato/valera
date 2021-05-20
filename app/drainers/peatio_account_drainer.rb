# frozen_string_literal: true

# Periodicaly fetch data from upstream and save it to account
#
class PeatioAccountDrainer < Drainer
  FETCH_PERIOD = 1 # sec

  KEYS = %i[balance].freeze

  def attach
    logger.info("Add periotic timer for #{FETCH_PERIOD} sec")
    EM.add_periodic_timer FETCH_PERIOD do
      update!
    end
  end

  def update!
    logger.debug 'update!' if ENV.true? 'DEBUG_DRAINER_UPDATE'
    account.update_attributes!(
      balances: fetch_balances,
      active_orders: fetch_active_orders
    )
  end

  private

  def fetch_active_orders
    # Collect by side
    client
      # .orders(market: market.peatio_symbol, type: OrdersUpdater::SIDES_MAP.fetch(side), state: :wait)
      .orders(market: market.peatio_symbol, state: :wait)
  end

  def fetch_balances
    account
      .client
      .account_balances
      .each_with_object(ActiveSupport::HashWithIndifferentAccess.new) { |r, a| a[r['currency']] = r['balance'] }
  end
end
