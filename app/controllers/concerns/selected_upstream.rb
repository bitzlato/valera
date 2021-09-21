# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

module SelectedUpstream
  extend ActiveSupport::Concern

  included do
    helper_method :selected_upstream
  end

  private

  def selected_upstream
    Upstream.find params[:upstream_id] if params[:upstream_id]
  end
end
