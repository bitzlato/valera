# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

module CurrentUser
  extend ActiveSupport::Concern

  included do
    helper_method :current_user
    before_action :authenticate!
  end

  private

  def authenticate!
    redirect_to Settings.signin_url.presence || root_url unless current_user.present?
  end

  def current_user
    @current_user ||= load_current_user
  end

  def load_current_user
    return OpenStruct.new(uid: ENV['FORCED_USER_ID']) if ENV.true? 'FORCED_USER_ID'

    unless request.env.key?('jwt.payload') # jwt.payload provided by rack-jwt
      Rails.logger.error 'No JWT payload to authenticate'
      return
    end

    payload = request.env['jwt.payload'].symbolize_keys
    unless payload[:state] == 'active'
      Rails.logger.warn "Wrong user state (#{payload[:state]})"
      return
    end

    OpenStruct.new(uid: payload[:uid])
  end
end
