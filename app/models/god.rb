class God
  include AutoLogger

  attr_reader :universes

  def initialize
    @universes = build_universes
  end

  def reset_settings!
    universes.each &:reset_settings!
  end

  def perform
    threads = universes.map do |universe|
      Thread.new do
        logger.info "Perform universe #{universe}"
        universe.perform_loop
      end
    end
    threads.each { |thr| thr.join }
  end

  #def peatio_markets
    #@peatio_markets ||= peatio_client.markets.map { |i| i['id'].to_s.upcase }
  #end

  private

  def build_universes
    universes = []
    Settings.bots.each_pair do |key, options|
      Market.all.map do |market|
        universes << Universe.new(key, market, options)
      end
    end
    universes
  end

end
