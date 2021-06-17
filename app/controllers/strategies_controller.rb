# frozen_string_literal: true

class StrategiesController < ApplicationController
  helper_method :selected_market

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

  private

  def selected_market
    Market.find params[:market_id] if params[:market_id]
  end
end
