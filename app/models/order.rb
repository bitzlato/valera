# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

#
# Order entity. Internal entity. Passed to peatio client to creating
#
class Order
  PRECISION = 4 # Gets from peatio config. Specific for every currency

  include Virtus.model
  include ActiveModel::AttributeAssignment
  include ActiveModel::Validations
  include Comparable
  include SideInquirer

  attribute :side, Symbol
  attribute :volume, BigDecimal
  attribute :price, BigDecimal
  attribute :level, Integer, default: 0

  validates :volume, presence: true, numericality: { greater_than: 0 }
  validates :price, presence: true, numericality: { greater_than: 0 }

  delegate :hash, to: :to_s

  attr_accessor :comparer

  def self.build(attrs)
    order = new(attrs)
    order.validate!
    order.freeze
  end

  def suitable?(other)
    return false if comparer.nil?

    comparer.call other
  end

  def human_side
    side?(:ask) ? 'sell' : 'buy'
  end

  def inspect
    to_s
  end

  def eql?(other)
    to_s == other.to_s
  end

  def <=>(other)
    return nil unless side == other.side

    volume_price <=> other.volume_price
  end

  def to_s
    "#{side}:#{format("%0.#{PRECISION}f", volume)}x#{format("%0.#{PRECISION}f", price)}"
  end

  def volume_price
    volume * price
  end

  def volume=(value)
    super value.round(PRECISION)
  end

  def price=(value)
    super value.round(PRECISION)
  end
end
