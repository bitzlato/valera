# frozen_string_literal: true

class Drainer
  INFLUX_TABLE = 'upstream'

  include AutoLogger
  include RedisModel
  extend Finders

  attr_reader :market, :logger, :account, :upstream_market, :id

  delegate :client, :upstream, to: :account

  def self.keys
    self::KEYS
  end

  def initialize(id:, market:, account:)
    @id = id
    @market = market
    @account = account
    @logger = ActiveSupport::TaggedLogging.new(_build_auto_logger).tagged(to_s)
    @upstream_market = market.upstream_markets.find_by_upstream! upstream
  end

  def self.model_name
    ActiveModel::Name.new(Drainer)
  end

  def attach
    raise 'not implemented'
  end

  private

  def update!(data)
    logger.debug data if ENV.true? 'DEBUG_DRAINER_UPDATE'
    upstream_market.update_attributes! data
    touch!
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
                                                                     upstream: upstream.id })
  end
end
