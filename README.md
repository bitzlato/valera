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
> docker exec -it grafana "grafana-cli --pluginUrl https://github.com/BrandyMint/ilgizar-candlestick-panel/archive/refs/tags/v1.2.zip plugins install ilgizar-candlestick-panel"

# Start web server, sidekiq, god and webpacker

> bundle exec foreman start

# Development

Run first bot only

> rails runner God.instance.universes.first.perform_loop

# TODO

* [ ] Manage trade values
* [ ] Cancel all orders on stop
* [ ] Reconnect or cancel all orders if socket is closed
