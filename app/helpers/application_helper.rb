module ApplicationHelper
  def middot
    content_tag :div, '&middot;'.html_safe, class: 'text-muted'
  end

  def app_title
    'VALERA'
  end

  def logged_in?
    false
  end

  def grafana_iframe_src(universe)
    "https://grafana.brandymint.ru/d-solo/ayEuw39Mz/valera?orgId=1&var-market=#{universe.market}&var-bot=#{universe.peatio_client.name}&panelId=2"
  end

  def present_latest_order(last_order, key, market)
    return middot if last_order.value.blank?
    data = JSON.parse(last_order)
    currency = key == :volume ? market.base : market.quote
    format_money(data[key.to_s], currency)
  end

  def format_percent(value)
    return middot if value.nil?
    value = value.value.to_d if value.is_a? Redis::Value
    content_tag :span, class: 'text-monospace' do
      (value * 100).to_s + '%'
    end
  end
end
