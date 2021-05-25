# frozen_string_literal: true

class TradesController < ApplicationController
  include PaginationSupport

  def index
    @q = Trade.ransack(params[:q])
    trades = @q.result.order('traded_at desc')
    render locals: { paginated_trades: paginate(trades), all_trades: trades }
  end

  def show
    redirect_to trades_path
  end
end
