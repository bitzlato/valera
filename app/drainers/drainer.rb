# frozen_string_literal: true

class Drainer
  WEBSOCKET_TYPE = :websocket
  POLLING_TYPE = :polling

  include AutoLogger
  include RedisModel
  extend Finders

  attr_reader :logger, :account, :id

  delegate :client, :upstream, to: :account

  def initialize(id:, account:)
    @id = id
    @account = account
    @logger = ActiveSupport::TaggedLogging.new(_build_auto_logger).tagged(to_s + '@' + account.try(:brief) || '-')
  end

  def self.type
    raise :undefined
  end

  def self.keys
    self::KEYS
  end

  def self.model_name
    ActiveModel::Name.new(Drainer)
  end

  def attach
    raise 'not implemented'
  end

  def simple_map(data, mapping)
    return data if mapping.blank?

    data.each_with_object({}) do |p, a|
      key, value = p
      a[mapping[key]] = value.to_d if mapping.key? key
    end
  end
end
