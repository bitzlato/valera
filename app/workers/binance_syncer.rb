class BinanceSyncer
  include Sidekiq::Worker

  def perform
    Market.all.each do |market|
      BinanceKlinesSyncer.new(market.binance_symbol).perform
    end
  end
end
