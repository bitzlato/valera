# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class StrategiesController < ApplicationController
  include SelectedMarket
  include SelectedStrategy

  def index
    strategies = god.strategies
    strategies.each(&:reload)
    strategies = strategies.sort_by(&:id)
    strategies = strategies.filter { |s| s.market == selected_market } if selected_market.present?
    strategies = strategies.filter { |s| s.instance_of?(selected_strategy) } if selected_strategy.present?
    render locals: { strategies: strategies }
  end

  def show
    strategy = Strategy.find! params[:id]
    render locals: { strategy: strategy }
  end
end
