# frozen_string_literal: true

# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

class EqualDrainer < Drainer
  KEYS = %i[tradePrice askPrice bidPrice].freeze

  attr_reader :markets, :upstream

  def initialize(id:, markets:, upstream:)
    super(id: id, account: nil)
    @markets = markets.map { |market_id| Market.find! market_id }
    @upstream = Upstream.find! upstream
  end

  def self.type
    POLLING_TYPE
  end

  def update!
    logger.debug 'update!' if ENV.true? 'DEBUG_DRAINER_UPDATE'
    markets.each do |market|
      price = 1.0
      data = { tradePrice: price, askPrice: price, bidPrice: price }
      upstream_market = market.upstream_markets.find_by_upstream! upstream
      upstream_market.update_attributes! data

      Valera::InfluxDB.client
                      .write_point(Settings.influx.collectors,
                                   values: data,
                                   tags: { market: market.id, upstream: upstream.id })
    end
    touch!
  rescue Valera::BaseClient::Error => e
    binding.pry
    report_exception e, true, strategy: self
    logger.error e
  end
end
