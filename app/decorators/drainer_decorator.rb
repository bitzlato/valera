# frozen_string_literal: true

class DrainerDecorator < ApplicationDecorator
  delegate_all

  def self.table_columns
    %i[id class market upstream account upstream_market]
  end
end
