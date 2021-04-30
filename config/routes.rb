Rails.application.routes.draw do
  root to: 'universes#index'
  resources :universes, only: [:index, :show]
  # For details on the DSL available within this file, see https://guides.rubyonrails.org/routing.html
end
