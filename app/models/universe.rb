class Universe
  EXPIRES_IN = 10.seconds
  include Singleton
  include AutoLogger

  # mcr - это rub

  DEAFULT_RATES = {
    ethbtc: 0.001,
    ethusdt: 0.001,
    btcusdt: 0.001
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
      botya.create_orders! DEAFULT_RATES[market], rate || raise("No default rate for #{market}")
    end
  end

  def perform
    markets.each do |market|
      perform_for_market market
    end
  end

  # Рынки доступные к сделкам (пересечение рынкоа на peatio и в источнике цен)
  def markets
    rates.keys
  end

  def rates
    Rails.cache.fetch self.class.name + '_rates', expires_in: EXPIRES_IN do
      KassaRates.new.rates.select { |k| peatio_markets.include? k }
    end
  end

  #
  def peatio_markets
    @peatio_markets ||= PeatioClient.new.markets.map { |i| i['id'].to_sym }
  end
end
