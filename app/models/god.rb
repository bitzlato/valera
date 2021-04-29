class God
  EXPIRES_IN = 10.seconds
  SLEEP = 1

  include AutoLogger
  extend AutoLogger

  def self.perform_for_all(do_loop = true)
    while true do
      Rails.application.credentials.bots.keys.each do |key|
        initialize_for(key).perform
      end
      if do_loop
        logger.info "Sleep for " + SLEEP.to_s
      else
        break
      end
    end
  end

  def self.initialize_for(key)
    data = Rails.application.credentials.bots.fetch key
    new(peatio_client: PeatioClient.new(data[:peatio]), options: data[:options])
  end

  def initialize(peatio_client: PeatioClient.new, options: {})
    @peatio_client = peatio_client
    @options = options
  end

  def perform
    peatio_markets.each do |market|
      logger.info "Perform for market #{market}"
      Universe
        .new(god: self, market: market, options: @options)
        .perform
    rescue => err
      logger.error err
    end
  end

  def peatio_markets
    @peatio_markets ||= peatio_client.markets.map { |i| i['id'].to_s.upcase }
  end

  attr_reader :peatio_client
end
