# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

module ApplicationHelper
  def active_class(css_classes, flag)
    flag ? "#{css_classes} active" : css_classes
  end

  def middot
    content_tag :div, '&middot;'.html_safe, class: 'text-muted'
  end

  def account_link(account)
    link_to "@#{account}", account_path(account.id)
  end

  def sorted_orders_by_side(orders, side)
    orders.to_a
          .filter { |o| o.side? side }
          .sort # sort_by { |o| side.downcase.to_s == 'ask' ? -o.price : o.price }
  end

  BG_SIDE_COLORS = { 'ask' => '#fee', 'bid' => '#efe' }.freeze
  def side_bg_color(side)
    BG_SIDE_COLORS[side.to_s]
  end

  def colorized_side(side)
    css_class = side.to_s == 'ask' ? 'badge badge-danger' : 'badge badge-success'
    content_tag :span, class: css_class do
      side
    end
  end

  def app_title
    'VALERA'
  end

  def logged_in?
    false
  end

  def grafana_iframe_src(resource, panel_id = nil)
    panel_id ||= Rails.application.credentials.grafana[:panel_id]
    case resource
    when Strategy
      Rails.application.credentials.grafana[:url] +
        "&var-market=#{resource.market.id}&var-bot=#{resource.name}&panelId=#{panel_id}"
    when Market
      Rails.application.credentials.grafana[:url] +
        "&var-market=#{resource.id}&var-bot=All&panelId=#{panel_id}"
    else
      raise "Inknown resource #{resource}"
    end
  end

  def present_time(time)
    return middot if time.nil?

    I18n.l time, format: :default
  end

  def present_latest_order(last_orders, side, key, currency)
    return middot if last_orders.nil?

    order = last_orders.find { |o| o['side'] == side }
    return middot if order.nil?

    format_money(order[key.to_s], currency)
  end

  def format_percent(value)
    return middot if value.nil?

    content_tag :span, class: 'text-monospace' do
      "#{value}%"
    end
  end

  def humanized_time_ago(time)
    if time.nil?
      t('.never')
    else
      content_tag :span, title: time do
        time_ago_in_words time, include_seconds: true
      end
    end
  end

  def settings_attribute_title(attribute)
    content_tag :span, title: attribute do
      t attribute, default: default_settings_attribute(attribute), scope: :settings_attributes
    end
  end
end
