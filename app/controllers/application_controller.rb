# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

class ApplicationController < ActionController::Base
  http_basic_authenticate_with **Rails.application.credentials.dig(:http_basic_auth) # if Rails.env.production?

  private

  def god
    @god ||= God.instance
  end
end
