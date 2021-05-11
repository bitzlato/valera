# frozen_string_literal: true

Rails.application.routes.draw do
  scope Settings.root_prefix do
    root to: 'universes#index'
    resources :universes, only: %i[index show]
    resources :markets, only: %i[index show]
    resources :universe_settings
  end
end
