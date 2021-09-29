# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

module MarketDrainer
  extend ActiveSupport::Concern

  included do
    attr_reader :market, :upstream_market

    def self.use_market?
      true
    end
  end

  def initialize(id:, market:, account: nil)
    super(id: id, account: account)
    @market = market || raise('Market must be present')
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
    data = data.compact
    return if data.empty?

    Valera::InfluxDB.client
                    .write_point(Settings.influx.collectors,
                                 values: data, tags: { market: market.id, upstream: upstream.id })
  end
end
