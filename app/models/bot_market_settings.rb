class BotMarketSettings
  include Redis::Objects

  value :bit_place_threshold
  value :ask_place_threshold

  def initialize(bot , market )
    @bot = bot.to_s.downcase
    @market = market.to_s.downcase
  end

  def id
    [@bot, @market].join(':')
  end
end
