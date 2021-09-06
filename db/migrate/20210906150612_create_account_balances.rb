# frozen_string_literal: true

# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

class CreateAccountBalances < ActiveRecord::Migration[6.1]
  def change
    create_table :account_balances do |t|
      t.string :account_id, null: false
      t.jsonb :balances, null: false, default: {}

      t.timestamps
    end
  end
end
