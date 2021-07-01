class Currency
  def self.round(currency, value)
    value.to_d.round(Settings.currencies.dig(currency, 'precision'), BigDecimal::ROUND_DOWN)
  end
end
