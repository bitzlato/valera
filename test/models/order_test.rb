# frozen_string_literal: true

class OrderTest < ActiveSupport::TestCase
  test 'invalid order' do
    refute Order.new.valid?
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
