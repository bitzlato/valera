# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class ApplicationController < ActionController::Base
  include CurrentUser

  private

  def god
    @god ||= God.instance
  end
end
