# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class BalancesController < ApplicationController
  def index
    currencies = (Market.all.map(&:currencies).flatten +
                  Account.all.map { |a| a.balances.transform_values { |v| v if v['available'].to_d + v['locked'].to_d > 0 }.compact.keys }.flatten).uniq
    render locals: {
      currencies: currencies,
      accounts: Account.all
    }
  end
end
