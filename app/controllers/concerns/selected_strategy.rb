# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

module SelectedStrategy
  extend ActiveSupport::Concern

  included do
    helper_method :selected_strategy
  end

  private

  def selected_strategy
    params[:strategy_name]
  end
end
