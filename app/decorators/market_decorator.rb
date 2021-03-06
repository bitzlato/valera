# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class MarketDecorator < ApplicationDecorator
  delegate_all

  def self.table_columns
    %i[id peatio_symbol binance_symbol base quote]
  end
end
