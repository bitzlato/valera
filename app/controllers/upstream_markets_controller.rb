# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class UpstreamMarketsController < ApplicationController
  def index
    upstream_markets = UpstreamMarket.all
    render locals: { upstream_markets: upstream_markets }
  end

  def show
    redirect_to upstream_markets_path
  end
end
