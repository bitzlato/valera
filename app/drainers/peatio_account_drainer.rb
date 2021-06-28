# frozen_string_literal: true

# Periodicaly fetch data from upstream and save it to account
#
class PeatioAccountDrainer < Drainer
  FETCH_PERIOD = 1 # sec

  KEYS = %i[balance].freeze

  def initialize(id:, account:)
    raise 'Account must be present' if account.nil?

    super id: id, account: account
  end

  def self.type
    POLLING_TYPE
  end

  def update!
    update_balances!
    update_active_orders!
    update_trades!
  end

  def update_balances!
    account.update_attributes!(
      balances_updated_at: Time.now, # Fetch time first
      balances: fetch_balances
    )
  rescue Valera::PeatilClient::Error => e
    logger.error e
    report_exception e
  end

  def update_active_orders!
    account.update_attributes!(
      active_orders_updated_at: Time.now, # Fetch time first
      active_orders: fetch_active_orders
    )
  rescue Valera::PeatilClient::Error => e
    logger.error e
    report_exception e
  end

  def update_trades!
    logger.debug 'update_trades!'
    client.trades.each do |raw_trade|
      market = Market.find_by(peatio_symbol: raw_trade['market']) # TODO: Move to Peatio Client
      if market.nil?
        logger.warn("Skip unknown market #{raw_trade['market']}")
        next
      end
      raw_trade['side'] = Peatio::Client::REST::SIDES_MAP.invert.fetch(raw_trade['side']) # TODO: Move to Peatio Client
      Trade
        .create_with(
          raw_trade.slice('price', 'amount', 'total', 'taker_type', 'side', 'order_id').merge(
            traded_at: raw_trade['created_at']
          )
        )
        .find_or_create_by!(
          trade_id: raw_trade['id'],
          market_id: market.id,
          account_id: account.id
        )
    end
    account.update_trades_amounts!
  rescue Valera::PeatilClient::Error => e
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
