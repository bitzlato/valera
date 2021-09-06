# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2021_09_06_150612) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"
  enable_extension "uuid-ossp"

  create_table "account_balances", force: :cascade do |t|
    t.string "account_id", null: false
    t.jsonb "balances", default: {}, null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "buyout_orders", force: :cascade do |t|
    t.string "trade_account_id", null: false
    t.uuid "original_trade_id", null: false
    t.decimal "volume", null: false
    t.decimal "price", null: false
    t.string "side", null: false
    t.string "market_id", null: false
    t.string "buyout_account_id", null: false
    t.integer "status", default: 0, null: false
    t.string "target_order_id"
    t.jsonb "meta", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "ignore_message"
    t.index ["buyout_account_id"], name: "index_buyout_orders_on_buyout_account_id"
    t.index ["market_id"], name: "index_buyout_orders_on_market_id"
    t.index ["trade_account_id", "original_trade_id"], name: "index_buyout_orders_on_trade_account_id_and_original_trade_id", unique: true
  end

  create_table "trades", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "market_id", null: false
    t.string "trade_id", null: false
    t.string "side", null: false
    t.string "taker_type", null: false
    t.datetime "traded_at", null: false
    t.decimal "total", null: false
    t.decimal "amount", null: false
    t.decimal "price", null: false
    t.string "account_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.bigint "order_id", null: false
    t.index ["account_id", "market_id", "trade_id"], name: "index_trades_on_account_id_and_market_id_and_trade_id"
    t.index ["account_id", "market_id", "traded_at", "side"], name: "index_trades_on_account_id_and_market_id_and_traded_at_and_side"
  end

end
