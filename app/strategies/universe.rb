# Bot universe for specific market
class Universe
  INFLUX_TABLE = 'processor'

  include AutoLogger
  include UpdatePeatioBalance
  extend UniverseFinders

  attr_reader :peatio_client, :market, :name, :state, :comment, :settings, :botya, :logger

  delegate :description, :settings_class, :state_class, :to => :class

  # @param name [String] key of bot from Rails credentials
  # @param market [Market]
  def initialize(name:, market:, peatio_client:, default_settings: {}, comment: nil)
    @name = name
    @market = market
    @default_settings = default_settings
    @peatio_client = peatio_client
    @botya = Botya.new(:market => market, :peatio_client => peatio_client, :name => name)
    @state = state_class.find_or_build id
    @comment = comment
    @logger = ActiveSupport::TaggedLogging.new(_build_auto_logger).tagged(id)
  end

  def self.description
    raise 'undefined strategy'
  end

  def self.settings_class
    return [name, 'Settings'].join('::').constantize if constants.include? :Settings
    UniverseSettings
  end

  def self.state_class
    return [name, 'State'].join('::').constantize if constants.include? :State
    UniverseState
  end

  def reload
    settings.safe_restore!
    state.safe_restore!
    self
  end

  def title
    "#{self.class.name}#{id}"
  end
  alias_method :to_s, :title

  # Change state
  # @param changes [Hash]
  def bump!(changes)
    logger.info "Bump with #{changes}"
    settings.restore!
    state.assign_attributes changes
    update_peatio_balances!

    orders = perform

    state.assign_attributes :last_orders => orders
    state.save!
    UniverseChannel.update self
  rescue StandardError => err
    report_exception err
    logger.error "#{to_s} #{err}"
  end

  def id
    [name, market.id].join('-')
  end
  alias_method :to_param, :id

  def reset_settings!
    settings_class.new(:id => id).update_attributes! @default_settings
    remove_instance_variable :@settings if instance_variable_defined? :@settings
  end

  def settings
    return @settings if instance_variable_defined? :@settings
    @settings = settings_class.find_or_build id, @default_settings
  end

  private

  def perform
    %i{ask bid}.map do |side|
      create_order(side, calculate_price(side), calculate_volume(side))
    end.compact
  end

  EX_SIDES = { :bid => :buy, :ask => :sell }

  def create_order(side, price, volume)
    logger.debug "create_order(#{side}, #{price}, #{volume})"
    botya.create_order! EX_SIDES.fetch(side), volume, price
    write_to_influx side, volume, price
    { :side => side, :price => price, :volume => volume }
  rescue StandardError => err
    report_exception err
    logger.error err
    nil
  end

  def calculate_price(side)
    raise 'not implemented'
  end

  def calculate_volume(side)
    raise 'not implemented'
  end

  def write_to_influx(side, volume, price)
    Valera::InfluxDB.client
      .write_point(
        INFLUX_TABLE,
        :values => { :"#{side}_volume" => volume, :"#{side}_price" => price },
        :tags => { :market => market.id, :bot => name }
    )
  end
end
