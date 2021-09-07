# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

Rails.application.routes.draw do
  root to: 'strategies#index'
  resources :strategies, only: %i[index show]
  resources :markets, only: %i[index show]
  resources :balances, only: %i[index]
  resources :strategy_settings
  resources :upstream_markets, only: %i[index show]
  resources :upstreams, only: %i[index show]
  resources :accounts, only: %i[index show]
  resources :drainers, only: %i[index show]
  resources :trades, only: %i[index show]
  resources :buyout_orders, only: %i[index show]
end
