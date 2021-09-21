# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class UpstreamMarketsController < ApplicationController
  include SelectedMarket
  include SelectedUpstream

  def index
    upstream_markets = UpstreamMarket.all
    upstream_markets = upstream_markets.filter { |s| s.market == selected_market } if selected_market.present?
    upstream_markets = upstream_markets.filter { |s| s.upstream == selected_upstream } if selected_upstream.present?
    render locals: { upstream_markets: upstream_markets }
  end

  def show
    redirect_to upstream_markets_path
  end
end
