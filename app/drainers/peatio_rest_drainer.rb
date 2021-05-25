# frozen_string_literal: true

# TODO: Rename to PatioMarketDrainer
#
class PeatioRestDrainer < MarketDrainer
  FETCH_PERIOD = 1 # sec

  KEYS = %i[asksVolume bidsVolume].freeze

  def self.type
    POLLING_TYPE
  end

  def update!
    logger.debug 'update!' if ENV.true? 'DEBUG_DRAINER_UPDATE'
    super(fetch_market_depth)
    write_to_influx upstream_market.attributes.slice(:usersAsksVolume, :usersBidsVolume)
  rescue Peatio::Client::REST::Error => e
    logger.error e
  end

  private

  # Returns asksVolume and bidsVolume fields
  def fetch_market_depth
    response = client
               .market_depth(market.peatio_symbol)

    data = response
           .slice('asks', 'bids')
           .transform_values { |v| depth_volume v }
           .transform_keys { |k| "#{k}Volume" }

    logger.debug("market_depth=#{data}")
    data
  end

  def depth_volume(grouped_orders)
    grouped_orders
      .inject(0.0) { |sum, row| sum + row.second.to_d }
  end
end
