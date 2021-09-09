# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class BalancesController < ApplicationController
  def index
    currencies = (Market.all.map(&:currencies).flatten +
                  Account.all.map do |a|
                    a.balances.transform_values do |v|
                      v if (v['available'].to_d + v['locked'].to_d).positive?
                    end.compact.keys
                  end.flatten).uniq
    render locals: {
      currencies: currencies,
      accounts: Account.all
    }
  end
end
