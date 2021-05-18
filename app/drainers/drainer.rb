# frozen_string_literal: true

class Drainer
  INFLUX_TABLE = 'upstream'

  include AutoLogger
  attr_reader :market, :logger, :upstream

  def self.upstream_tag
    name.underscore.split('_').first
  end

  def self.keys
    self::KEYS
  end

  delegate :upstream_tag, to: :class

  def initialize(market)
    @market = market
    @logger = ActiveSupport::TaggedLogging.new(_build_auto_logger).tagged([self.class.name, market].join('/'))
    @upstream = Upstream.all.find { |u| u.id == upstream_tag } || raise("Not found upstream #{upstream_tag}")
  end

  def to_s
    "[#{self.class.name}]#{market}"
  end

  def attach
    raise 'not implemented'
  end

  def upstream_market
    @upstream_market ||= market.upstream_markets.find_by_upstream! upstream
  end

  private

  def update!(data)
    upstream_market.update_attributes! data
    write_to_influx data
  end

  def simple_map(data, mapping)
    return data if mapping.blank?

    data.each_with_object({}) do |p, a|
      key, value = p
      a[mapping[key]] = value.to_d if mapping.key? key
    end
  end

  def write_to_influx(data)
    Valera::InfluxDB.client
                    .write_point(INFLUX_TABLE, values: data, tags: { market: market.id,
                                                                     upstream: upstream_tag })
  end
end
