# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

# TODO: Rename to PatioMarketDrainer
#
class PeatioRestDrainer < Drainer
  include MarketDrainer

  FETCH_PERIOD = 1 # sec

  KEYS = %i[asksVolume bidsVolume usersAskPrice usersBidPrice usersAsksVolume usersBidsVolume].freeze

  def self.type
    POLLING_TYPE
  end

  def update!
    logger.debug 'update!' if ENV.true? 'DEBUG_DRAINER_UPDATE'
    data = fetch_market_depth.merge fetch_order_book
    upstream_market.update_attributes! data
    touch!
    write_to_influx data.merge(upstream_market.attributes.slice(:usersAsksVolume, :usersBidsVolume))
  rescue Valera::BaseClient::Error => e
    report_exception e
    logger.error e
  end

  private

  def fetch_order_book
    response = client
               .order_book(market.peatio_symbol,
                           asks_limit: 2,
                           bids_limit: 2,
                           exclude_member_id: account.peatio_member_id)

    {
      usersAskPrice: response['asks'].first&.fetch('price', nil)&.to_d_if_presence,
      usersBidPrice: response['bids'].first&.fetch('price', nil)&.to_d_if_presence
    }
  end

  # Returns asksVolume and bidsVolume fields
  def fetch_market_depth
    response = client
               .market_depth(market.peatio_symbol)

    data = response
           .slice('asks', 'bids')
           .transform_values { |v| depth_volume v }
           .transform_keys { |k| "#{k}Volume".to_sym }

    logger.debug("market_depth=#{data}")

    data
  end

  def depth_volume(grouped_orders)
    grouped_orders
      .inject(0.0) { |sum, row| sum + row.second.to_d }
  end
end
