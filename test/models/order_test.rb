# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

require 'test_helper'

class OrderTest < ActiveSupport::TestCase
  test 'invalid order' do
    refute Order.new.valid?
  end

  test 'comparing' do
    origin = Order.new price: 123, comparer: ->(other) { other.price == 123 }

    assert origin.suitable?(Order.new(price: origin.price))
    refute origin.suitable?(Order.new(price: 999))
  end

  test 'equal' do
    assert_equal(
      Order.build(side: :ask, price: 1, volume: 1),
      Order.build(side: :ask, price: 1, volume: 1)
    )
  end

  test '>=' do
    assert Order.build(side: :ask, price: 1.0001, volume: 1) >= Order.build(side: :ask, price: 1, volume: 1)
  end

  test '<=' do
    assert Order.build(side: :ask, price: 1.0001, volume: 0.9) <= Order.build(side: :ask, price: 1, volume: 1)
  end

  test 'find difference' do
    set2 = Set[
      Order.build(side: :ask, price: 0.998, volume: 1),
      Order.build(side: :ask, price: 0.999, volume: 2),
      Order.build(side: :ask, price: 1.002, volume: 1)
    ]
    set1 = Set[
      Order.build(side: :ask, price: 1.002, volume: 1),
      Order.build(side: :ask, price: 1.001, volume: 2)
    ]

    assert_equal set2 & set1, Set[Order.build(side: :ask, price: 1.002, volume: 1)]
  end
end
