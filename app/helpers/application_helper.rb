module ApplicationHelper
  def middot
    content_tag :div, '&middot;'.html_safe, class: 'text-muted'
  end

  def present_latest_order(last_order, key, market)
    return middot if last_order.value.blank?
    data = JSON.parse(last_order)
    currency = key == :volume ? market.base : market.quote
    format_money(data[key.to_s], currency)
  end
end
