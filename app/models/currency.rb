# frozen_string_literal: true

# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

class Currency
  def self.round(currency, value)
    precision = Money::Currency.find(currency.split('-').first).precision
    value.to_d.round(precision, BigDecimal::ROUND_DOWN)
  end
end
