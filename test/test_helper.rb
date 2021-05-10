# frozen_string_literal: true

ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
require 'rails/test_help'
require 'minitest/mock'
Dir[File.expand_path('support/**/*.rb', __dir__)].sort.each { |rb| require(rb) }

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Setup all fixtures in test/fixtures/*.yml for all tests in alphabetical order.
    fixtures :all

    def around(&block)
      client = Class.new
      def client.write_point(*args); end
      Valera::InfluxDB.stub(:client, client, &block)
    end
  end
end
