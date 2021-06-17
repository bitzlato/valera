# frozen_string_literal: true
#
class BuyoutOrderDecorator < ApplicationDecorator
  delegate_all
  def self.table_columns
    %i[id created_at updated_at trade_account volume price]
  end
end
