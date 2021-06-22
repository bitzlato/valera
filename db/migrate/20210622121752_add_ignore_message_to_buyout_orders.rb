# frozen_string_literal: true

class AddIgnoreMessageToBuyoutOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :buyout_orders, :ignore_message, :string
  end
end
