class BotSettings
  include ActiveModel::Model
  include Redis::Objects

  list :markets

  attr_accessor :bot

  def id
    bot.downcase
  end
end
