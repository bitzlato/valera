# frozen_string_literal: true

class Market
  extend ActiveModel::Naming
  include ActiveModel::Conversion
  attr_reader :quote, :base, :upstream_states

  def self.all
    God.markets
  end

  # @param id<String> Example: BTC_USDT
  def self.find(id)
    all.find { |m| m.id == id }
  end

  def initialize(base, quote)
    @base = base
    @quote = quote
    @upstream_states = Settings.upstreams.keys
      .each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |upstream, a|
      a[upstream.to_sym] = UpstreamMarket.find_or_create! upstream: upstream, market: self
    end
  end

  def persisted?
    true
  end

  def notify_changes!
    universes.each &:notify_changes!
  end

  def universes
    God.universes.select { |u| u.market == self }
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
