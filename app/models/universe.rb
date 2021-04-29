class Universe
  EXPIRES_IN = 10.seconds
  SLEEP = 1

  include AutoLogger
  extend AutoLogger

  # mcr - это rub

  DEAFULT_RATES = {
    ethbtc: 0.0001,
    ethusdt: 0.0001,
    btcusdt: 0.0001,
    btcmcr: 0.0001,
    ethmcr: 0.0001,
    usdtmcr: 1,
  }

  def self.perform_for_all
    Rails.application.credentials.bots.keys.each do |key|
      initialize_for(key).perform
    end
  end

  def self.loop_for_all
    while true do
      perform_for_all
      logger.info "Sleep for " + SLEEP.to_s
    end
  end

  def self.initialize_for(key)
    data = Rails.application.credentials.bots.fetch key
    new(data[:options].reverse_merge peatio_client: PeatioClient.new(data[:peatio]))
  end

  def initialize(peatio_client: PeatioClient.new, bit_place_threshold: , ask_place_threshold:)
    @peatio_client = peatio_client
    @bit_place_threshold = bit_place_threshold
    @ask_place_threshold = ask_place_threshold
  end

  def loop
    while true do
      perform
      logger.info 'loop'
      sleep 1
    end
  end

  def perform_for_market(market)
    botya = Botya.new(market: market, client: peatio_client, bit_place_threshold: bit_place_threshold, ask_place_threshold: ask_place_threshold)
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
        logger.debug "Has rate for market #{market}: #{rates[market]}, performing.."
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

  def peatio_markets
    @peatio_markets ||= peatio_client.markets.map { |i| i['id'].to_sym }
  end

  private

  attr_reader :peatio_client, :bit_place_threshold, :ask_place_threshold
end
