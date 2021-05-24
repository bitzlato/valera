# frozen_string_literal: true

class MarketDrainer < Drainer
  attr_reader :market

  def initialize(id:, market:, account:)
    super(id: id, account: account)
    @market = market
    @upstream_market = market.upstream_markets.find_by_upstream! upstream
  end

  private

  def update!(data)
    logger.debug data if ENV.true? 'DEBUG_DRAINER_UPDATE'
    upstream_market.update_attributes! data
    touch!
    write_to_influx data
  end

  def write_to_influx(data)
    Valera::InfluxDB.client
                    .write_point(Settings.influx.collectors,
                                 values: data, tags: { market: market.id, upstream: upstream.id })
  end
end
