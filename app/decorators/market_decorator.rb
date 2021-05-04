class MarketDecorator < ApplicationDecorator
  delegate_all
  def self.table_columns
    %i[symbol base quote]
  end
end
