# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

set :stage, :production
set :user, 'valera'
set :rails_env, :production
fetch(:default_env)[:rails_env] = :production
set :linked_files, %w[.env config/master.key config/credentials/production.key]

server ENV.fetch('PRODUCTION_SERVER'), user: fetch(:user), roles: fetch(:roles)
