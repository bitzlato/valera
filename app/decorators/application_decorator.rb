# frozen_string_literal: true

class ApplicationDecorator < Draper::Decorator
  TEXT_RIGHT = %i[debit balance credit amount locked total price available_amount locked_amount total_amount].freeze

  delegate :current_user, :humanized_money_with_currency, to: :h

  def self.table_columns
    object_class.attribute_names.map(&:to_sym)
  end

  def self.table_th_class(column)
    return 'text-right' if TEXT_RIGHT.include? column
  end

  def self.table_td_class(column)
    table_th_class column
  end

  def self.table_tr_class(record); end

  def self.attributes
    table_columns
  end

  def self.attribute_title(attr)
    a = attr.to_s.split('_')
    postfix = a.many? ? a.last : nil
    if postfix.present? && I18n.available_locales.include?(postfix.to_sym)
      a.pop
      attr = a.join('_')
      locale_postfix = " (#{postfix})"
    end

    buffer = I18n.t attr,
                    scope: [:decorators, decorated_class_key],
                    default: decorated_class.human_attribute_name(attr)

    buffer << locale_postfix if locale_postfix.present?
    buffer
  end

  def self.decorated_class_key
    name.underscore.sub('_decorator', '')
  end

  def self.decorated_class
    name.sub('Decorator', '').sub('Admin::', '').constantize
  end

  def side
    h.colorized_side object.side
  end

  def created_at
    h.content_tag :span, class: 'text-nowrap', title: object.updated_at do
      I18n.l object.created_at, format: :default
    end
  end

  def updated_at
    h.content_tag :span, class: 'text-nowrap', title: object.updated_at do
      I18n.l object.updated_at, format: :default
    end
  end

  private

  def t(key)
    I18n.t key
  end

  def time_formatted(time)
    return '-' unless time

    I18n.l time, format: :long
  end

  def flash_highlight(buffer)
    h.content_tag :div, buffer.html_safe, data: { effect: 'highlight' }
  end
end
