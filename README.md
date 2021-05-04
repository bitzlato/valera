# Valera

Automated crypto currency trading software for peatio 

# Install

> nvm install; yarn install
> rvm install; bundle

# Configure and seeding

> echo "create database valera_development;" | influx
> rake db:create db:migrate db:seed

# Start web server, sidekiq, god and webpacker

> bundle exec foreman start

# Development

Run first bot only

> rails runner God.new.universes.first.perform_loop
