# frozen_string_literal: true

# Periodicaly fetch data from upstream and save it in MarketUpsteamState
#
class PeatioRestDrainer < Drainer
  FETCH_PERIOD = 1 # sec

  KEYS = %i[asksVolume bidsVolume].freeze

  def attach
    logger.info("Add periotic timer for #{FETCH_PERIOD} sec")
    EM.add_periodic_timer FETCH_PERIOD do # sec
      logger.debug('Timer executed')
      fetch_and_update_market_depth!
    end
  end

  private

  def fetch_and_update_market_depth!
    Async do
      update_market_depth! client.market_depth market.peatio_symbol
    end
  end

  def update_market_depth!(data)
    # TODO: You can save market depth if you want
    #
    asks = depth_volume data['asks']
    bids = depth_volume data['bids']

    update! asksVolume: asks, bidsVolume: bids
  end

  def depth_volume(grouped_orders)
    grouped_orders.inject(0.0) { |sum, row| sum + row.first.to_d * row.second.to_d }
  end
end
