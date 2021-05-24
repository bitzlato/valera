# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class God
  include AutoLogger
  include Singleton

  class << self
    def method_missing(method, *args)
      return instance.send(method, *args) if instance.respond_to? method

      super
    end

    def respond_to_missing?(method)
      instance.respond_to?(method) || super(method)
    end
  end

  def initialize
    SdNotify.status('God was born!')
    logger.info('God was born!')
  end

  def accounts
    @accounts ||= build_accounts.freeze
  end

  def strategies
    @strategies ||= build_strategies.freeze
  end

  def markets
    @markets ||= build_markets.freeze
  end

  def upstreams
    @upstreams ||= build_upstreams.freeze
  end

  def drainers
    @drainers ||= build_drainers.freeze
  end

  def websocket_collectors
    drainers.filter { |d| d.class.type == Drainer::WEBSOCKET_TYPE }
  end

  def polling_collectors
    drainers.filter { |d| d.class.type == Drainer::POLLING_TYPE }
  end

  def reset_settings!
    strategies.each(&:reset_settings!)
  end

  private

  def build_accounts
    Settings.accounts.each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |pair, hash|
      key, config = pair
      credentials = Rails.application.credentials.bots.fetch(config['credentials'].to_sym) if config.key?('credentials')
      upstream = upstreams.fetch config['upstream']
      if upstream.credential_client_class.present?
        client = upstream.credential_client_class.new(**credentials.merge(name: config['credentials'].to_sym))
      end
      hash[key] = Account.new(
        id: key,
        upstream: upstream,
        client: client
      )
    end
  end

  def build_drainers
    Settings.drainers.map do |key, config|
      drainer_class = config['class'].constantize

      if drainer_class.ancestors.include? MarketDrainer
        # TODO: Use available for drainers markets only config[:markets]
        Market.all.map do |market|
          drainer_class.new(
            id: key,
            market: market,
            account: Account.find(config['account'])
          )
        end
      else
        drainer_class.new(
          id: key,
          account: Account.find(config['account'])
        )
      end
    end.flatten
  end

  def build_upstreams
    Settings.upstreams.each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |pair, hash|
      id, options = pair
      client_class = options.key?('credential_client') ? options['credential_client'].constantize : nil
      hash[id] = Upstream.new id: id, credential_client_class: client_class
    end
  end

  def build_markets
    Settings.markets
            .each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |name, a|
      a[name] = Market.new(*name.split('_'))
    end
  end

  def build_strategies
    strategies = Set.new
    Settings.strategies.each_pair do |key, options|
      Market.all.map do |market|
        strategy_class = options['class'].constantize
        settings = options.fetch('settings', {})
        settings = settings.fetch('global', {}).merge settings.dig('markets', market.id) || {}

        strategies << strategy_class.new(
          name: key,
          market: market,
          account: accounts.fetch(options['account']),
          default_settings: settings,
          comment: options['comment']
        )
      end
    end
    strategies
  end
end
# rubocop:enable Metrics/ClassLength
