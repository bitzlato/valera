# Periodicaly fetch data from upstream and save it in MarketUpsteamState
#
class PeatioRestDrainer < Drainer
  FETCH_PERIOD = 1 # sec

  KEYS = %i{asksVolume bidsVolume}.freeze

  def attach
    logger.info("add periotic timer #{FETCH_PERIOD}")
    EM.add_periodic_timer FETCH_PERIOD do # sec
      logger.info("periotic timer")
      fetch_and_update_market_depth!
      # TODO fetch and update balance
    end
  end

  private

  def fetch_and_update_market_depth!
    Async do
      update_market_depth! client.market_depth market.peatio_symbol
    end
  end

  def update_market_depth! data
    # TODO You can save market depth if you want
    #
    asks = depth_volume data['asks']
    bids = depth_volume data['bids']

    update! asksVolume: asks, bidsVolume: bids
  end

  def depth_volume(grouped_orders)
    grouped_orders.inject(0.0) { |sum, row| sum + row.first.to_d * row.second.to_d }
  end

  def client
    @client ||= PeatioClient.new
  end
end
