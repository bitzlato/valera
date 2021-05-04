class Market
  attr_reader :quote, :base, :symbol, :binance_syncer

  def self.all
    Settings.markets.map do |name|
      Market.new(*name.split(':'))
    end
  end

  def initialize(base , quote )
    @base = base
    @quote = quote
    @binance_syncer = BinanceKlinesSyncer.new binance_symbol
  end

  def id
    symbol
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
