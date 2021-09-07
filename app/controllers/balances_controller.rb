# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class BalancesController < ApplicationController
  def index
    render locals: {
      currencies: Market.all.map(&:currencies).flatten.uniq,
      accounts: Account.all
    }
  end
end
