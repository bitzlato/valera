# Bot universe for specific market
class Universe
  INTERVAL = '1m'

  include AutoLogger

  attr_reader :peatio_client, :market, :bot_key, :options, :state

  def self.find(id)
    God.instance.universes.find { |u| u.id == id }
  end

  # @param bot_key [String] key of bot from Rails credentials
  # @param market [Market]
  def initialize(bot_key, market, options = {})
    @bot_key = bot_key
    @market = market
    @options = options
    @peatio_client = PeatioClient.new Rails.application.credentials.bots.fetch(bot_key.to_sym).merge(name: bot_key)
    @botya = Botya.new(market: market, peatio_client: peatio_client, name: bot_key)
    @state = InputData.new
  end

  def description
    options.fetch('description', id)
  end

  alias_method :to_s, :description
  alias_method :id, :to_param

  # Change state
  def bump!(changes)
    state.assign_attributes changes
    logger.info "Perform #{to_s} with #{state}"

    Processor
      .new(botya: @botya, market: market, options: bot_market_settings)
      .perform state
  rescue => err
    Bugsnag.notify err
    logger.error "#{to_s} #{err}"
  end

  def id
    [bot_key, market].join(':')
  end

  def last_data
    @last_data ||= UniverseLastData.new(bot_key, market)
  end

  def bot_market_settings
    @bot_market_settings ||= BotMarketSettings.new(bot_key, market)
  end

  def reset_settings!
    options['all_markets'].each_pair do |attr, value|
      bot_market_settings.send attr + '=', value
    end
  end
end
