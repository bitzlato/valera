class CreateTrades < ActiveRecord::Migration[6.1]
  def change
    create_table :trades do |t|
      t.string :market_id, null: false
      t.integer :trade_id, null: false
      t.string :side, null: false
      t.string :taker_type, null: false
      t.timestamp :traded_at, null: false
      t.decimal :total, null: false
      t.decimal :amount, null: false
      t.decimal :price, null: false
      t.string :account_id, null: false

      t.timestamps
    end

    add_index :trades, [:account_id, :market_id, :trade_id]
    add_index :trades, [:account_id, :market_id, :traded_at, :side]
  end
end
