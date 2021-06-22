# frozen_string_literal: true

# rubocop:disable Layout/LineLength
ENV['JWT_PUBLIC_KEY'] =
  'LS0tLS1CRUdJTiBQVUJMSUMgS0VZLS0tLS0KTUlJQklqQU5CZ2txaGtpRzl3MEJBUUVGQUFPQ0FROEFNSUlCQ2dLQ0FRRUF4MGRnQzRJckdIRWpMKzVzTDlJSAo5K0tLSlBtMHdtT2J0SzdtTjQ4MW1qeHlzVTF2QURScnR5TUh5OEZVRlNTSGg1RlJqQm4renlLNStOczQ5c2ZECmJON2R3blUxMTNnOW1pdnRoNGVHM2xHT3RURXJNS0F2VkZ0Z1kySDY4VnR3bFJ1a3BrUHh0eC80Y3o4aUVUaVAKRjlUT2xoRGhoSjRra3owL2JYaDNRMUtFSmJSdHNXWFgzNnRrMk04VGJXOVNEUEplOHFoUTcwTmNKaHlOTWp1ZwpuOExQU0YzOXZwbHRKcVcwcUhlaEtDRzBUeXlnbVlEMHlxTk9FWXhmUUV4aW0xd1hYZ1ZZOHNvM1ZidGtxRjRGCkkvWHdiZzNCeTZHWlNEVDJwT05kdTN3OWNOSGVJaGZhWUpVN1YxNUIwQU4xTk1Qb0xvejAxNUcyRzVqZmN4ZmoKdFFJREFRQUIKLS0tLS1FTkQgUFVCTElDIEtFWS0tLS0tCg=='
# rubocop:enable Layout/LineLength
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require_relative './support/sqlite_test_db_loader'
require 'rails/test_help'
require 'minitest/mock'
Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |rb| require(rb) }

# This assumes you're sharing config between unit/integration
module TestSetup
  extend ActiveSupport::Concern

  included do
    fixtures :all

    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Make sure that you reload the sqlite when starting processes
    parallelize_setup do
      # slightly more efficient than a direct call to establish_connection
      ActiveRecord::Migration.check_pending!
    end

    def around(&block)
      client = Class.new
      def client.write_point(*args); end
      Valera::InfluxDB.stub(:client, client, &block)
    end
  end
end

module ActiveSupport
  class TestCase
    include TestSetup
  end
end

module ActionDispatch
  class IntegrationTest
    include TestSetup
  end
end
