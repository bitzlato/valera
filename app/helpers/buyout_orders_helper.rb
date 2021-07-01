# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

module BuyoutOrdersHelper
  STATUS_CLASSES = {
    'ignored' => 'badge badge-secondary',
    'done' => 'badge badge-success',
    'posted' => 'badge badge-warn',
    'default' => 'badge badge-info',
    'errored' => 'badge badge-danger'
  }.freeze

  def buyout_order_status(buyout_order)
    css_class = STATUS_CLASSES[buyout_order.status] || STATUS_CLASSES['default']
    content_tag :span, class: css_class do
      BuyoutOrder.human_enum_name(:status, buyout_order.status)
    end
  end
end
