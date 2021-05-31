# Valera

Automated crypto currency trading software for peatio 

# Install

> nvm install; yarn install
> rvm install; bundle

# Configure and seeding

> echo "create database valera_development;" | influx
> rake db:create db:migrate db:seed

# Start grafana

```
docker run -d -p 7000:3000 --restart=always -v /var/lib/grafana:/var/lib/grafana --name=grafana -e GF_SECURITY_ALLOW_EMBEDDING=true -e GF_AUTH_ANONYMOUS_ENABLED=true grafana/grafana
docker exec -it grafana "grafana-cli --pluginUrl https://github.com/BrandyMint/ilgizar-candlestick-panel/archive/refs/tags/v1.2.zip plugins install ilgizar-candlestick-panel"
```

# Start web server, sidekiq, god and webpacker

> bundle exec foreman start

## Configure barong

> docker exec -it opendax_barong_1 bundle exec rails runner \
  'Permission.create!([ { role: :superadmin, verb: :all, path: :valera, action: :accept }, \
  { role: :admin, verb: :all, path: :valera, action: :accept }, \
  { role: :accountant, verb: :all, path: :valera, action: :accept }])'

# Development

Run first bot only

> rails runner God.instance.universes.first.perform_loop

# Other

>  TechnicalAnalysis::Rsi.calculate(DataFetcher.fetch(market: 'BTC_USDT'), period: 5, price_key: :close)

# TODO

* [ ] Не делать и не отменять заявки если они в пределах допустимого
* [ ] Automaticalyy cancel all orders if there are no fresh data from more then
  N msecs
* [ ] Check maker/collector oneness (store pid and host name of runners)
* [ ] Reconnect websockets

# Deployment

## Setup

```
export PRODUCTION_HOST=<YOUR_SERVER_IP> 
bundle exec cap production systemd:puma:setup systemd:daemon:setup master_key:setup
bundle exec cap production config:set RAILS_ENV=production RAILS_SERVE_STATIC_FILES=true BUGSNAG_API_KEY=$BUGSNAG_API_KEY VALERA_REDIS_URL=redis://localhost:6379/4
```

## Regular deploy

```
bundle exec cap production deploy
```

