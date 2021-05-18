# frozen_string_literal: true

class Upstream
  extend Finders
  include RedisModel

  attr_reader :credential_client_class

  def initialize(id:, credential_client_class:)
    @credential_client_class = credential_client_class
    super id: id
  end

  def drainers
    @drainers ||= God.drainers.filter { |d| d.upstream == self }
  end

  # TODO: List only using makets
  #
  def markets
    @markets ||= Market.all
  end

  def upstream_markets
    @upstream_markets ||=
      UpstreamMarkets
      .new(markets.map { |market| market.upstream_markets.find_by_upstream!(self) })
  end
end
