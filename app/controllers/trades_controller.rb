# frozen_string_literal: true

class TradesController < ApplicationController
  def index
    @q = Trade.ransack(params[:q])
    render locals: { trades: @q.result.order('traded_at desc') }
  end

  def show
    redirect_to trades_path
  end
end
