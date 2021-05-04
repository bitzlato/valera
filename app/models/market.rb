class Market
  attr_accessor :quote, :base, :symbol

  def self.all
    Settings.markets.map do |name|
      Market.new.tap do |m|
        m.base, m.quote = name.split(':')
        m.symbol = (m.base + m.quote)
      end.freeze
    end
  end

  def to_s
    symbol.to_s
  end

  def peatio_symbol
    symbol.downcase
  end

  def binance_symbol
    symbol.upcase.gsub('MCR', 'RUB')
  end
end
