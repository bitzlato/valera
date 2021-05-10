require 'sidekiq/web'
require 'sidekiq/cron/web'
Rails.application.routes.draw do
  root :to => 'universes#index'
  mount Sidekiq::Web => 'sidekiq'
  resources :universes, :only => %i[index show]
  resources :markets, :only => %i[index show]
  resources :universe_settings
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
