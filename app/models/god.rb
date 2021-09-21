# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class God
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
      upstream = upstreams.fetch(config['upstream'].presence || raise("No upstream key in account section (#{key})"))
      raise "No upstream client_class for #{upstream}" if upstream.client_class.nil?

      credentials = config.fetch('credentials', nil)
      if credentials.present?
        credentials = credentials.is_a?(Hash) ? credentials.reverse_merge(name: key) : fetch_credentials(credentials)
        client = upstream.client_class.new(**credentials.symbolize_keys)
      else
        client = upstream.client_class.new
      end

      hash[key] = Account.new(id: key, upstream: upstream, client: client)
    rescue ArgumentError => e
      raise "#{e} with #{key}=>#{pair} #{upstream.try :client_class}"
    end
  end

  def fetch_credentials(credentials)
    Rails.application.credentials.accounts.fetch(credentials.to_sym).merge(name: credentials.to_sym)
  end

  def build_drainers
    Settings.drainers.map do |key, config|
      drainer_class = config['class'].constantize
      attrs = config.except('class').symbolize_keys.merge(id: key)
      attrs[:account] = Account.find!(config['account']) if attrs.key? :account

      if drainer_class.respond_to?(:use_market?)
        Market.all.map do |market|
          drainer_class.new(**attrs.merge(market: market))
        end
      else
        drainer_class.new(**attrs)
      end
    end.flatten
  end

  def build_upstreams
    Settings.upstreams.each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |pair, hash|
      id, options = pair
      client_class = options.key?('client') ? options['client'].constantize : nil
      hash[id] = Upstream.new id: id, client_class: client_class
    end
  end

  def build_markets
    Settings.markets
            .each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |name, a|
      market = case name
               when String
                 Market.build_by_id(name)
               when Hash
                 Market.new(**name.symbolize_keys)
               else
                 raise "Uknown market definition type #{name.class} (#{name})"
               end
      a[market.id] = market
    end
  end

  def build_strategies
    strategies = Set.new
    Settings.strategies.each_pair do |key, options|
      Market.all.map do |market|
        strategy_class = options['class'].constantize
        settings = options.fetch('settings', {})
        settings = settings.fetch('global', {}).merge settings.dig('markets', market.id) || {}

        attrs = {
          name: key,
          market: market,
          account: accounts.fetch(options['account']),
          source_account: accounts.fetch(options['source_account']),
          default_settings: settings,
          comment: options['comment']
        }
        attrs[:buyout_account] = accounts.fetch(options['buyout_account']) if options.key? 'buyout_account'
        strategies << strategy_class.new(**attrs)
      end
    end
    strategies
  end
end
# rubocop:enable Metrics/ClassLength
