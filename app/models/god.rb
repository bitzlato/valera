class God
  SLEEP = 1

  include AutoLogger

  def self.reset_settings!
    Settings.bots.each_pair do |key, options|
      Settings.markets.each do |market|
        bm = BotMarketSettings.new(key, market)
        options['all_markets'].each_pair do |attr, value|
          bm.send attr + '=', value
        end
      end
    end
  end

  def perform(do_loop = true)
    while true do
      universes.each do |universe|
        logger.info "Perform universe #{universe}"
        universe.perform
      end
      if do_loop
        logger.info "Sleep for " + SLEEP.to_s
      else
        break
      end
    end
  end

  private

  #def peatio_markets
    #@peatio_markets ||= peatio_client.markets.map { |i| i['id'].to_s.upcase }
  #end

  def universes
    @universes ||= Rails.application.credentials.bots.keys.map { |key| Settings.markets.map { |market| Universe.new(key, market) }}.flatten
  end
end
