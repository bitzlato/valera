module ApplicationHelper
  GRAFANA_URL = 'https://grafana.brandymint.ru/d-solo/ayEuw39Mz/valera?orgId=1&refresh=5s'
  GRAFANA_DEFAULT_PANEL_ID = 8
  def middot
    content_tag :div, '&middot;'.html_safe, :class => 'text-muted'
  end

  def app_title
    'VALERA'
  end

  def logged_in?
    false
  end

  def grafana_iframe_src(resource, panel_id = GRAFANA_DEFAULT_PANEL_ID)
    if resource.is_a? Universe
      GRAFANA_URL + "&var-market=#{resource.market.id}&var-bot=#{resource.name}&panelId=#{panel_id}"
    elsif resource.is_a? Market
      GRAFANA_URL + "&var-market=#{resource.id}&var-bot=All&panelId=#{panel_id}"
    else
      raise "Inknown resource #{resource}"
    end
  end

  def present_latest_order(last_orders, side, key, currency)
    return middot if last_orders.nil?
    order = last_orders.find { |order| order['side'] == side }
    return middot if order.nil?
    format_money(order[key.to_s], currency)
  end

  def format_percent(value)
    return middot if value.nil?
    content_tag :span, :class => 'text-monospace' do
      "#{value}%"
    end
  end
end
