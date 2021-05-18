# frozen_string_literal: true

Rails.application.routes.draw do
  get '/', to: redirect(Settings.root_prefix)
  scope Settings.root_prefix do
    root to: 'strategies#index'
    resources :strategies, only: %i[index show]
    resources :markets, only: %i[index show]
    resources :strategy_settings
    resources :upstream_markets, only: %i[index show]
    resources :upstreams, only: %i[index show]
  end
end
