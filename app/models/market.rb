# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class Market
  extend ActiveModel::Naming
  extend Finders
  include ActiveModel::Conversion
  attr_reader :quote, :base, :peatio_symbol, :binance_symbol, :binance_quote, :enable_buyout, :monolithos_symbol,
              :huobi_symbol

  def self.build_by_id(symbol)
    base, quote = *symbol.split('_')
    new(base: base, quote: quote)
  end

  # rubocop:disable Metrics/ParameterLists
  def initialize(base:,
                 quote:,
                 peatio_symbol: nil,
                 binance_quote: nil,
                 binance_symbol: nil,
                 huobi_symbol: nil,
                 enable_buyout: false,
                 monolithos_symbol: nil)
    @base = base
    @quote = quote
    @peatio_symbol = peatio_symbol || [base, quote].join('_').remove('-').downcase
    @binance_symbol = binance_symbol
    @binance_quote = binance_quote || quote if @binance_symbol.present?
    @huobi_symbol = huobi_symbol
    @monolithos_symbol = monolithos_symbol
    @enable_buyout = enable_buyout
  end
  # rubocop:enable Metrics/ParameterLists

  def currencies
    [base, quote]
  end

  def upstream_markets
    @upstream_markets ||= UpstreamMarkets.new(
      Upstream
      .all
      .filter { |u| u.markets.include?(self) }
      .map { |u| UpstreamMarket.build upstream: u, market: self }
    )
  end

  def active_orders
    Account
      .all
      .active_orders
      .filter { |o| o.market == market }
      .flatten
  end

  def reload
    self
  end

  def persisted?
    true
  end

  def notify_changes!
    strategies.each(&:notify_changes!)
  end

  def strategies
    God.strategies.select { |u| u.market == self }
  end

  def ==(other)
    other.try(:id) == id
  end

  def id
    [base, quote].join('_')
  end

  # humanized name
  def name
    [base, quote].join('/')
  end

  def variable_name
    id.gsub('-', '__')
  end

  def to_s
    name.to_s
  end
end
