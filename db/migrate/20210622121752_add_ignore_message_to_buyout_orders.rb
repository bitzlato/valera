# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class AddIgnoreMessageToBuyoutOrders < ActiveRecord::Migration[6.1]
  def change
    add_column :buyout_orders, :ignore_message, :string
  end
end
