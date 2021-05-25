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
    update_trades!
    account.update_trades_amounts!
  rescue Peatio::Client::REST::Error => e
    logger.error e
    report_exception e
  end

  private

  def update_trades!
    client.trades.each do |raw_trade|
      Trade
        .create_with(
          raw_trade.slice('price', 'amount', 'total', 'taker_type').merge(
            side:  Peatio::Client::REST::SIDES_MAP.invert.fetch(raw_trade['side']), # TODO Move to Peatio Client
            traded_at: raw_trade['created_at']
          )
        )
        .find_or_create_by(
          trade_id: raw_trade['id'],
          market_id: Market.find_by!(peatio_symbol: raw_trade['market']), # TODO Move to Peatio Client
          account_id: account.id
      )
    end
  end

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
