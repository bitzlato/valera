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
        universes << Universe.new(key, market, options)
      end
    end
    universes
  end
end
