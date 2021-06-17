class BuyoutOrdersController < ApplicationController
  include PaginationSupport

  def index
    @q = BuyoutOrder.ransack(params[:q])
    orders = @q.result.order('created_at desc')
    render locals: { paginated_orders: paginate(orders), all_orders: orders }
  end

  def show
    redirect_to buyout_orders_path
  end
end
