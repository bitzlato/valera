class Drainer
  INFLUX_TABLE = 'upstream'

  include AutoLogger
  attr_reader :market, :logger

  def self.upstream_tag
    name.underscore.split('_').first
  end

  delegate :upstream_tag, to: :class

  def initialize(market)
    @market = market
    @logger = ActiveSupport::TaggedLogging.new(_build_auto_logger).tagged([self.class.name, market].join('/'))
  end

  def attach
    raise 'not implemented'
  end

  private

  def simple_map(data, mapping)
    return data if mapping.blank?

    data.each_with_object({}) do |p, a|
      key, value = p
      a[mapping[key]] = value.to_d if mapping.key? key
    end
  end

  def bump!(data)
    return if data.blank?

    write_to_influx data
    market.universes.each do |universe|
      universe.bump!(
        data.transform_keys { |key| [upstream_tag, key].join('_') }
      )
    end
  end

  def write_to_influx(data)
    Valera::InfluxDB.client
                    .write_point(INFLUX_TABLE, values: data, tags: { market: market.id,
                                                                     upstream: self.class.upstream_tag })
  end
end
