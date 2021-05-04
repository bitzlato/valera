# Valera

Automated crypto currency trading software for peatio 

# Install

> nvm install; yarn install
> rvm install; bundle

# Configure and seeding

> echo "create database valera_development;" | influx
> rake db:create db:migrate db:seed

# Start grafana

> docker run -d -p 7000:3000 --name=grafana -e GF_SECURITY_ALLOW_EMBEDDING=true grafana/grafana

# Start web server, sidekiq, god and webpacker

> bundle exec foreman start

# Development

Run first bot only

> rails runner God.instance.universes.first.perform_loop

# TODO

Manage trade values
