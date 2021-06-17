class AddOrderIdToTrades < ActiveRecord::Migration[6.1]
  def change
    Trade.delete_all
    add_column :trades, :order_id, :bigint, null: false
    add_index :trades, :order_id
  end
end
