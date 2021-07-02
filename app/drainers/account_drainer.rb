# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

# Periodicaly fetch data from upstream and save it to account
#
class AccountDrainer < Drainer
  FETCH_PERIOD = 1 # sec

  KEYS = %i[balance].freeze

  def initialize(id:, account:, interval: 10)
    raise 'Account must be present' if account.nil?
    raise 'Interval must be greater or equal to 1 second' if interval.to_i < 1

    @interval = interval
    @last_update_at = nil
    super id: id, account: account
  end

  def self.type
    POLLING_TYPE
  end

  def update!
    if @last_update_at.is_a?(Time) && @last_update_at > @interval.seconds.ago
      logger.warn("Skip update until interval (#{@interval} meet")
    end
    update_balances!
    update_active_orders!
    update_trades!
    @last_update_at = Time.now
  end

  def update_balances!
    account.update_attributes!(
      balances_updated_at: Time.now, # Save time first
      balances: account.client.account_balances.tap { |balances| logger.debug("balances=#{balances}") }
    )
  rescue Valera::BaseClient::Error => e
    logger.error e
    report_exception e
  end

  def update_active_orders!
    account.update_attributes!(
      active_orders_updated_at: Time.now, # Save time first
      active_orders: client.open_orders.tap { |open_orders| logger.debug("open_orders=#{open_orders}") }
    )
  rescue Valera::BaseClient::Error => e
    logger.error e
    report_exception e
  end

  def update_trades!
    logger.debug 'update_trades!'
    client.my_trades(account.markets).each do |raw_trade|
      if raw_trade['market'].nil?
        logger.warn("Skip unknown market #{raw_trade['market_symbol']}")
        next
      end
      Trade
        .create_with(
          raw_trade.slice('price', 'amount', 'total', 'taker_type', 'side', 'order_id', 'market').merge(
            traded_at: raw_trade['created_at']
          )
        )
        .find_or_create_by!(
          trade_id: raw_trade['id'],
          account_id: account.id
        )
    end
    account.update_trades_amounts!
  rescue Valera::BaseClient::Error => e
    logger.error e
    report_exception e
  end
end
