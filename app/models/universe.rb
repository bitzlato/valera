# Bot universe for specific market
class Universe
  INTERVAL = '1m'

  include AutoLogger

  attr_reader :peatio_client, :market, :name, :options, :state, :description

  def self.find(id)
    God.instance.universes.find { |u| u.id == id }
  end

  # @param name [String] key of bot from Rails credentials
  # @param market [Market]
  def initialize(name, market, options = {})
    @name = name
    @market = market
    @options = options
    @peatio_client = PeatioClient.new Rails.application.credentials.bots.fetch(options['credentials'].to_sym).merge(name: name)
    @botya = Botya.new(market: market, peatio_client: peatio_client, name: name)
    @state = UniverseState.new id: id
    @state.restore!
    @description = options.fetch('description', '')
  end

  alias_method :to_s, :name

  # Change state
  # @param changes [Hash]
  def bump!(changes)
    state.assign_attributes changes
    update_peatio_balances!
    logger.info "Perform #{to_s} with #{state}"

    orders = Processor
      .new(botya: @botya, market: market, options: bot_market_settings)
      .perform state

    state.assign_attributes last_orders: orders
    state.save!
  rescue => err
    Bugsnag.notify err
    logger.error "#{to_s} #{err}"
  end

  def id
    [name, market.id].join(':')
  end
  alias_method :to_param, :id

  def bot_market_settings
    @bot_market_settings ||= BotMarketSettings.new(name, market.id)
  end

  def reset_settings!
    options['all_markets'].each_pair do |attr, value|
      bot_market_settings.send attr + '=', value
    end
  end

  private

  def find_balance(balances, currency)
    data = balances.find { |b| b['currency'] == currency }
    return data['balance'].to_d if data.has_key? 'balance'
  end

  def update_peatio_balances!
    balances = peatio_client.account_balances
    state.assign_attributes(
      peatio_base_balance: find_balance(balances, market.base.downcase),
      peatio_quote_balance: find_balance(balances, market.quote.downcase)
    )
  end
end
