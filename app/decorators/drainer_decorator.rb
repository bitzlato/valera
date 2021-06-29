# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class DrainerDecorator < ApplicationDecorator
  delegate_all

  def self.table_columns
    %i[id updated_at drainer_class market upstream account upstream_market]
  end

  def drainer_class
    object.class
  end

  def market
    object.try(:upstream_market).try(:market)
  end

  def upstream_market
    object.try(:upstream_market)
  end
end
