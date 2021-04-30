module UniverseRedisObject
  extend ActiveSupport::Concern
  included do
    include Redis::Objects
    self.keys.each do |key|
      value key
    end
  end

  def initialize(bot , market )
    @bot = bot.to_s.downcase
    @market = market.to_s.downcase
  end

  def as_json(_args = {})
    self.class.keys.each_with_object({}) { |e, a| a[e] = send(e).value }
  end

  def id
    [@bot, @market].join(':')
  end
end
