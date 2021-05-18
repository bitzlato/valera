# frozen_string_literal: true

class God
  include AutoLogger
  include Singleton

  attr_reader :drainers

  class << self
    delegate :strategies, :markets, :upstreams, :drainers, :logger, to: :instance
  end

  def initialize
    @drainers = Set.new
  end

  def strategies
    @strategies ||= build_strategys
  end

  def markets
    @markets ||= build_markets
  end

  def upstreams
    @upstreams ||= build_upstreams
  end

  def reset_settings!
    strategies.each(&:reset_settings!)
  end

  private

  def build_upstreams
    Settings.upstreams.map do |key, config|
      Upstream.new key, config
    end
  end

  def build_markets
    Settings.markets.map do |name|
      Market.new(*name.split(':'))
    end
  end

  def build_strategies
    strategies = []
    Settings.strategies.each_pair do |key, options|
      markets.map do |market|
        strategy_class = options['class'].constantize
        settings = options.fetch('settings', {})
        settings = settings.fetch('global', {}).merge settings.dig('markets', market.id) || {}

        # TODO Use clients pool
        peatio_client = PeatioClient.new(
          **Rails.application.credentials.bots
          .fetch(options['credentials'].to_sym)
          .merge(name: key)
        )
        strategies << strategy_class.new(name: key, market: market, peatio_client: peatio_client,
                                        default_settings: settings, comment: options['comment'])
      end
    end
    strategies
  end
end
