# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

module SelectedMarket
  extend ActiveSupport::Concern

  included do
    helper_method :selected_market
  end

  private

  def selected_market
    Market.find params[:market_id] if params[:market_id]
  end
end
