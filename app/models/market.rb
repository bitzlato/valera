# frozen_string_literal: true

class Market
  extend ActiveModel::Naming
  extend Finders
  include ActiveModel::Conversion
  attr_reader :quote, :base

  def initialize(base, quote)
    @base = base
    @quote = quote
  end

  def upstream_markets
    @upstream_markets ||= UpstreamMarkets.new(
      Upstream.all.map { |u| UpstreamMarket.build upstream: u, market: self }
    )
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
    other.id == id
  end

  def id
    [base, quote].join('_')
  end

  def symbol
    base + quote
  end

  def to_s
    id.to_s
  end

  def peatio_symbol
    symbol.downcase
  end

  def binance_symbol
    symbol.upcase.gsub('MCR', 'RUB')
  end
end
