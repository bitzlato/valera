# frozen_string_literal: true

class TradesController < ApplicationController
  def index
    trades = Trade.order('traded_at desc')
    render locals: { trades: trades }
  end

  def show
    redirect_to trades_path
  end
end
