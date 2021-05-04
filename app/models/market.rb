class Market
  attr_reader :quote, :base, :symbol, :binance_syncer

  def self.all
    Settings.markets.map do |name|
      Market.new(*name.split(':'))
    end
  end

  def self.find(id)
    all.find { |m| m.id == id }
  end

  def universes
    God.instance.universes.select { |u| u.market == self }
  end

  def ==(other)
    other.id == id
  end

  def initialize(base , quote )
    @base = base
    @quote = quote
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
