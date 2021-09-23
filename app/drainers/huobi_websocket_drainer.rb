# frozen_string_literal: true

# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# EM.run { Huobi::Websocket.new.tap { |h| h.market_ticker!(:btcusdt) } }
#
class HuobiWebsocketDrainer < WebsocketDrainer
  MAPPING = {
    open: :open,
    high: :high,
    low: :low,
    close: :close,
    lastPrice: :tradePrice,
    lastSize: :tradeQuantity,
    bid: :bidPrice,
    bidSize: :bidQty,
    ask: :askPrice,
    askSize: :askQty
    # amount
    # vol
    # count
  }.freeze

  KEYS = MAPPING.values

  attr_reader :markets

  def initialize(id:, markets:, account:)
    raise "Account for drainer #{id} must be present" if account.nil?

    super(id: id, account: account)
    @markets = markets.map { |market_id| Market.find market_id }
  end

  private

  def streams
    markets.map do |market|
      "market.#{market.huobi_symbol}.ticker"
    end.uniq
  end

  def message(data)
    SdNotify.status('Drainer message')
    raise "Unknown data scheme #{data}" unless data.fetch(:ch) =~ /^market\.([a-z]+)\.ticker$/

    mapped_data = simple_map data.fetch(:tick).slice(*MAPPING.keys), MAPPING

    markets.select { |m| m.huobi_symbol == Regexp.last_match(1) }.each do |market|
      upstream_market = market.upstream_markets.find_by_upstream! upstream
      upstream_market.update_attributes! mapped_data
      touch!
      Valera::InfluxDB.client
                      .write_point(Settings.influx.collectors,
                                   values: mapped_data, tags: { market: market.id, upstream: upstream.id })
    end
  end

  def ws_client
    @ws_client ||= Huobi::Websocket.new
  end
end
