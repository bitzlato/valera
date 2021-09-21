# frozen_string_literal: true

# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

class MonolithosDrainer < Drainer
  KEYS = %i[tradePrice].freeze

  attr_reader :markets

  def initialize(id:, account:, markets:)
    super(id: id, account: account)
    @markets = markets.map { |market_id| Market.find! market_id }
  end

  def self.type
    POLLING_TYPE
  end

  def update!
    logger.debug 'update!' if ENV.true? 'DEBUG_DRAINER_UPDATE'
    client.fetch.each do |row|
      # MDT_MCR
      symbol = [row['first_currency'], row['second_currency']].join('_')

      market = markets.find { |m| m.monolithos_symbol == symbol }
      next if market.nil?

      price = row.fetch('price').to_d

      raise "zero price for #{row}" if price.zero?

      data = { tradePrice: price, askPrice: price, bidPrice: price }
      upstream_market = market.upstream_markets.find_by_upstream! upstream
      upstream_market.update_attributes! data
      touch!

      Valera::InfluxDB.client
                      .write_point(Settings.influx.collectors,
                                   values: data,
                                   tags: { market: market.id, upstream: upstream.id })
    end
    touch!
  rescue Valera::BaseClient::Error => e
    report_exception e
    logger.error e
  end
end
