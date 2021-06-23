# frozen_string_literal: true

class StrategiesController < ApplicationController
  include SelectedMarket

  def index
    strategies = god.strategies
    strategies.each(&:reload)
    strategies = strategies.filter { |s| s.market == selected_market } if selected_market.present?
    render locals: { strategies: strategies }
  end

  def show
    strategy = Strategy.find! params[:id]
    render locals: { strategy: strategy }
  end
end
