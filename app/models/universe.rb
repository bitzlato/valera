class Universe
  EXPIRES_IN = 10.seconds
  include Singleton
  include AutoLogger

  # mcr - это rub

  DEAFULT_RATES = {
    ethbtc: 0.0001,
    ethusdt: 0.0001,
    btcusdt: 0.0001,
    btcmcr: 0.0001,
    ethmcr: 0.0001,
    usdtmcr: 1,
  }

  def loop
    while true do
      perform
      logger.info 'loop'
      sleep 1
    end
  end

  def perform_for_market(market)
    botya = Botya.new(market)
    rate = rates[market]
    if rate.to_f == 0
      logger.warn "No rate for #{market}, cancel all orders!"
      botya.cancel_orders!
    else
      logger.info "Perform market #{market}"
      botya.create_orders! DEAFULT_RATES[market] || raise("No default volume for #{market}"), rate
    end
  end

  def perform
    rates = KassaRates.new.rates
    peatio_markets.each do |market|
      if rates.has_key? market
        perform_for_market market
      else
        logger.warn "No rates for market #{market}"
      end
    end
  end

  # Рынки доступные к сделкам (пересечение рынкоа на peatio и в источнике цен)
  def markets
    rates.keys
  end

  def rates
    Rails.cache.fetch self.class.name + '_rates', expires_in: EXPIRES_IN do
      KassaRates.new.rates
    end
  end

  #
  def peatio_markets
    @peatio_markets ||= PeatioClient.new.markets.map { |i| i['id'].to_sym }
  end
end
