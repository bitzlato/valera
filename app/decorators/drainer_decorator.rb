# frozen_string_literal: true

class DrainerDecorator < ApplicationDecorator
  delegate_all

  def self.table_columns
    %i[id drainer_class market upstream account upstream_market]
  end

  def drainer_class
    object.class
  end
end
