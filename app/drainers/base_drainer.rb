# frozen_string_literal: true

class BaseDrainer
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
    logger.info "Attach streams #{streams}"
    SdNotify.status('Drainer attach')
    client.multi(streams: streams, methods: methods)
  end

  def open(event)
    SdNotify.status('Drainer open')
    dump_headers event
    logger.info "Open connection, start universes #{market.universes.map(&:to_s)}"
    market.universes.each(&:start!)
  end

  def error(event)
    # Possible event.message:
    # Errno::ECONNRESET
    Bugsnag.notify event.message do |b|
      b.meta_data = { market_id: market.id }
    end
    logger.error "Error (#{event.type}) with message #{event.message}"

    if event.message == Errno::ECONNRESET
      logger.warn 'Reattach'
      attach
    elsif Rails.env.development?
      binding.pry # rubocop:disable Lint/Debugger
    end
  end

  def close(event = nil)
    dump_headers event
    logger.warn "Closed connection with code #{event.code}, stop universes #{market.universes.map(&:to_s)}"
    market.universes.each do |universes|
      universes.stop! 'due closed connection'
    end
  end

  def message(event)
    SdNotify.status('Drainer message')
    dump_headers event
    data = JSON.parse(event.data)
    logger.debug data
    catch :ignoreMessage do
      bump! map data
    end
  end

  private

  def map(_data)
    raise 'not implemented'
  end

  def simple_map(data, mapping)
    return data if mapping.blank?

    data.each_with_object({}) do |p, a|
      key, value = p
      a[mapping[key]] = value.to_d if mapping.key? key
    end
  end

  def methods
    %i[open message error close].each_with_object({}) do |m, a|
      a[m] = method m
    end
  end

  def write_to_influx(data)
    Valera::InfluxDB.client
                    .write_point(INFLUX_TABLE, values: data, tags: { market: market.id,
                                                                     upstream: self.class.upstream_tag })
  end

  def client
    raise 'not implemented'
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

  def dump_headers(event)
    logger.debug event.target.headers.inspect
  end
end
