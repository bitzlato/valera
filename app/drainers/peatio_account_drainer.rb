# frozen_string_literal: true

# Periodicaly fetch data from upstream and save it to account
#
class PeatioAccountDrainer < Drainer
  FETCH_PERIOD = 1 # sec

  KEYS = %i[balance].freeze

  def self.type
    POLLING_TYPE
  end

  def update!
    logger.debug 'update!' if ENV.true? 'DEBUG_DRAINER_UPDATE'
    account.update_attributes!(
      balances: fetch_balances,
      active_orders: fetch_active_orders
    )
  rescue Peatio::Client::REST::Error => e
    logger.error e
    report_exception e
  end

  private

  def fetch_active_orders
    # Collect by side
    active_orders = client
                    .orders(state: :wait)
    logger.debug("active_orders=#{active_orders}")
    active_orders
  end

  def fetch_balances
    balances = account
               .client
               .account_balances
               .each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |r, a|
      a[r['currency']] =
        r['balance']
    end
    logger.debug("balances=#{balances}")
    balances
  end
end
