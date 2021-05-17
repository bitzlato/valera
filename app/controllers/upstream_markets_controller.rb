# frozen_string_literal: true

class UpstreamMarketsController < ApplicationController
  def index
    upstream_markets = UpstreamMarket.all
    render locals: { upstream_markets: upstream_markets }
  end
end
