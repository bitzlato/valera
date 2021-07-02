# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

Money.rounding_mode = BigDecimal::ROUND_HALF_UP
# rubocop:disable Style/ClassAndModuleChildren
#
# Remove all currencies
Money::Currency.all.each do |cur|
  Money::Currency.unregister cur.id.to_s
end

# Add our currencies
Psych.load(File.read('./config/currencies.yml')).each { |_key, cur| Money::Currency.register cur.symbolize_keys }

# Create currency constants
Money::Currency.all.each do |cur|
  Object.const_set cur.iso_code, cur
end

class Money::Currency
  def self.all_crypto
    @all_crypto ||= all.select(&:is_crypto?)
  end

  def zero_money
    Money.from_amount(0, self)
  end

  def is_crypto?
    !!data[:is_crypto]
  end

  def precision
    data[:precision] || Math.log10(subunit_to_unit).to_i
  end

  private

  def data
    self.class.table[@id]
  end
end
# rubocop:enable Style/ClassAndModuleChildren
