# frozen_string_literal: true

class BuyoutOrdersController < ApplicationController
  include SelectedMarket
  include PaginationSupport

  def index
    @q = BuyoutOrder.ransack(params[:q])
    orders = @q.result

    orders = orders.where(market_id: selected_market.id) if selected_market.present?

    orders = orders.order('created_at desc')
    render locals: { paginated_orders: paginate(orders), all_orders: orders }
  end

  def show
    redirect_to buyout_orders_path
  end
end
