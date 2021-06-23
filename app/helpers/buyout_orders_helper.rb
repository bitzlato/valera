# frozen_string_literal: true

module BuyoutOrdersHelper
  STATUS_CLASSES = {
    'ignored' => 'badge badge-danger',
    'done' => 'badge badge-success',
    'default' => 'badge badge-info'
  }.freeze
  def buyout_order_status(buyout_order)
    css_class = STATUS_CLASSES[buyout_order.status] || STATUS_CLASSES['default']
    content_tag :span, class: css_class do
      BuyoutOrder.human_enum_name(:status, buyout_order.status)
    end
  end
end
