# frozen_string_literal: true

require 'connection_pool'
Redis::Objects.redis = ConnectionPool.new(size: 5, timeout: 5) do
  Redis.new url: ENV.fetch('VALERA_REDIS_URL', 'redis://localhost:6379/4')
end
