# frozen_string_literal: true

module StrategyFinders
  def all
    God.instance.strategies
  end

  def find(id)
    raise 'ID must present' if id.blank?

    all.find { |u| u.id == id }.reload
  end
end
