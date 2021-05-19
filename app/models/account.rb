# frozen_string_literal: true

# You account on upstream
#
class Account
  include RedisModel
  extend Finders

  attr_reader :upstream, :client

  attribute :balances, Hash
  attribute :active_orders, Array[PersistedOrder]

  def initialize(id:, upstream:, client:)
    super id: id
    @upstream = upstream
    @client = client
  end
end
