class CreatePersistedOrders < ActiveRecord::Migration[6.1]
  def change
    create_table :persisted_orders do |t|
      t.string :side, null: false
      t.decimal :origin_volume, null: false
      t.decimal :remaining_volume, null: false
      t.decimal :price, null: false
      t.string :market_id, null: false
      t.string :account_id, null: false
      t.jsonb :raw, null: false

      t.timestamps
    end

    add_index :persisted_orders, :market_id
    add_index :persisted_orders, :account_id
  end
end
