# frozen_string_literal: true

class CreateBuyoutOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :buyout_orders do |t|
      t.string :trade_account_id, null: false
      t.uuid :original_trade_id, null: false
      t.decimal :volume, null: false
      t.decimal :price, null: false
      t.string :side, null: false
      t.string :market_id, null: false
      t.string :buyout_account_id, null: false
      t.integer :status, null: false, default: 0
      t.string :target_order_id
      t.jsonb :meta, null: false

      t.timestamps
    end

    add_index :buyout_orders, %i[trade_account_id original_trade_id], unique: true
    add_index :buyout_orders, :market_id
    add_index :buyout_orders, :buyout_account_id
  end
end
