# frozen_string_literal: true

Rails.application.routes.draw do
  get '/', to: redirect(Settings.root_prefix)
  scope Settings.root_prefix do
    root to: 'universes#index'
    resources :universes, only: %i[index show]
    resources :markets, only: %i[index show]
    resources :universe_settings
    resources :upstream_markets
    resources :upstreams, only: %i[index]
  end
end
