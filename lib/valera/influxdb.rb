# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

module Valera
  module InfluxDB
    class << self
      def client(opts = {})
        # Map InfluxDB clients with received opts.
        clients[opts] ||= ::InfluxDB::Client.new(parse(config.merge(opts)))
      end

      def config
        yaml = ::Pathname.new('config/influxdb.yml')
        return {} unless yaml.exist?

        erb = ::ERB.new(yaml.read)
        ::SafeYAML.load(erb.result)[ENV.fetch('RAILS_ENV', 'development')].deep_symbolize_keys || {}
      end

      def clients
        @clients ||= {}
      end

      def parse(configs)
        hosts = configs[:host]
        return configs if hosts.nil?

        configs[:host] = hosts[Zlib.crc32(configs[:keyshard].to_s) % hosts.count]
        configs
      end
    end
  end
end
