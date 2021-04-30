# Bot universe for specific market
class Universe
  INTERVAL = '1m'

  include AutoLogger

  attr_reader :peatio_client, :market, :bot_key, :options

  def initialize(bot_key, market, options = {})
    @bot_key = bot_key
    @market = market
    @options = options
    @peatio_client = PeatioClient.new Rails.application.credentials.bots.fetch bot_key.to_sym
    @botya = Botya.new(market: market.downcase, client: peatio_client)
  end

  def description
    options.fetch('description', id)
  end

  def perform_loop
    loop do
      perform
    end
  end

  def perform
    logger.info "Perform #{to_s}"
    symbol = binance_symbol(market)
    klines = BinanceClient.instance.klines(symbol: symbol, interval: INTERVAL, limit: 1)

    # TODO Create value object
    input_data = OpenStruct.new(kline: klines.first)

    Processor
      .new(botya: @botya, market: market, input_data: input_data, options: bot_market_settings)
      .perform
  rescue => err
    logger.error "#{to_s} #{err}"
  end

  def to_s
    description
  end

  def to_param
    id
  end

  def id
    [bot_key, market].join(':')
  end

  def bot_market_settings
    @bot_market_settings ||= BotMarketSettings.new(bot_key, market)
  end

  def binance_symbol(market)
    market.gsub('MCR', 'RUB')
  end

  def reset_settings!
    options['all_markets'].each_pair do |attr, value|
      bot_market_settings.send attr + '=', value
    end
  end
end
