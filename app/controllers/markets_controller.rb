class MarketsController < ApplicationController
  def index
    render locals: { markets: Market.all }
  end

  def show
    market = Market.find params[:id]
    render locals: { market: market }
  end
end
