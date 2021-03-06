# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class AccountsController < ApplicationController
  def index
    accounts = Account.all
    render locals: { accounts: accounts }
  end

  def show
    redirect_to accounts_path
  end
end
