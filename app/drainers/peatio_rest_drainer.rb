# frozen_string_literal: true

# Periodicaly fetch data from upstream and save it in MarketUpsteamState
#
class PeatioRestDrainer < Drainer
  FETCH_PERIOD = 1 # sec

  KEYS = %i[asksVolume bidsVolume].freeze

  def attach
    logger.info("Add periotic timer for #{FETCH_PERIOD} sec")
    EM.add_periodic_timer FETCH_PERIOD do # sec
      update!
    end
  end

  def update!
    logger.debug 'update!' if ENV.true? 'DEBUG_DRAINER_UPDATE'
    super(
      fetch_market_depth
    )
  end

  private

  def fetch_market_depth
    client
      .market_depth(market.peatio_symbol)
      .slice('asks', 'bids')
      .transform_values { |v| depth_volume v }
      .transform_keys { |k| k+'Volume' }
  end

  def depth_volume(grouped_orders)
    grouped_orders.inject(0.0) { |sum, row| sum + row.first.to_d * row.second.to_d }
  end
end
