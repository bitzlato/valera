class God
  include AutoLogger
  include Singleton

  attr_reader :universes

  def initialize
    @universes = build_universes
  end

  def reset_settings!
    universes.each &:reset_settings!
  end

  private

  def build_universes
    universes = []
    Settings.bots.each_pair do |key, options|
      Market.all.map do |market|
        settings = options.fetch('settings', {})
        settings = settings.fetch('global', {}).merge settings.dig('markets', market.id) || {}
        peatio_client = PeatioClient.new Rails.application.credentials.bots.fetch(options['credentials'].to_sym).merge(name: key)
        universes << Universe.new(name: key, market: market, peatio_client: peatio_client, default_settings: settings, description: options['description'])
      end
    end
    universes
  end
end
