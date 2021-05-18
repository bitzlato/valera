# frozen_string_literal: true

class AccountsController < ApplicationController
  def index
    accounts = Account.all
    render locals: { accounts: accounts }
  end
end
