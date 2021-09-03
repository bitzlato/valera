# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class Market
  extend ActiveModel::Naming
  extend Finders
  include ActiveModel::Conversion
  attr_reader :quote, :base, :peatio_symbol, :binance_symbol, :binance_quote, :enable_buyout

  def self.build_by_id(symbol)
    base, quote = *symbol.split('_')
    new(base: base, quote: quote)
  end

  def initialize(base:, quote:, peatio_symbol: nil, binance_quote: nil, binance_symbol: nil, enable_buyout: false)
    @base = base
    @quote = quote
    @peatio_symbol = peatio_symbol || (base + quote).downcase
    @binance_symbol = binance_symbol || (base + quote).upcase
    @binance_quote = binance_quote || quote
    @enable_buyout = enable_buyout
  end

  def currencies
    [base, quote]
  end

  def upstream_markets
    @upstream_markets ||= UpstreamMarkets.new(
      Upstream.all.map { |u| UpstreamMarket.build upstream: u, market: self }
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

  def variable_name
    id.gsub('-','__')
  end

  def to_s
    id.to_s
  end
end
