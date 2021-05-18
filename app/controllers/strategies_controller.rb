# frozen_string_literal: true

class StrategiesController < ApplicationController
  def index
    strategies = god.strategys
    strategies.each(&:reload)
    render locals: { strategies: strategys }
  end

  def show
    strategy = Strategy.find params[:id]
    render locals: { strategy: strategy }
  end
end
