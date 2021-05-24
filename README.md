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

* [x] Interactively Enable/Disable strategy
* [x] Cancel all orders on stop
* [x] Cancel all orders if socket is closed
* [x] Manage trade values
* [ ] Automaticalyy cancel all orders if there are no fresh data from more then
  N msecs
* [x] Throw order book through websocket in peatio
* [x] Move active orders fetching to separate drainer
* [ ] Check maker/collector oneness
* [x] Вместо base_threshold два отклонения от цены
* [ ] Максимальный объём торговли в сутки для проторговщика
* [ ] Не делать и не отменять заявки если они в пределах допустимого

# Deployment

## Setup

1. Add `PRODUCTION_HOST` and `STAGING_HOST` to `.envrc`
2. Initialize directory and configs structure on the server

> bundle exec cap $STAGE systemd:puma:setup systemd:daemon:setup master_key:setup

3. Add env varliables to the server .env file

> bundle exec cap $STAGE config:set RAILS_ENV=$STAGE \
  RAILS_SERVE_STATIC_FILES=true \
  BUGSNAG_API_KEY=??? \
  VALERA_REDIS_URL=redis://localhost:6379/4 \
  JWT_PUBLIC_KEY=??? \

## Regular deploy

> bundle exec cap $STAGE deploy

