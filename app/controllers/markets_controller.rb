# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class MarketsController < ApplicationController
  def index
    render locals: { markets: Market.all }
  end

  def show
    market = Market.find! params[:id]
    render locals: { market: market }
  end
end
