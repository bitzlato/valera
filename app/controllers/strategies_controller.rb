# frozen_string_literal: true

class StrategiesController < ApplicationController
  def index
    strategies = god.strategies
    strategies.each(&:reload)
    render locals: { strategies: strategies }
  end

  def show
    strategy = Strategy.find params[:id]
    render locals: { strategy: strategy }
  end
end
