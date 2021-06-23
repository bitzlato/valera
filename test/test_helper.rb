# frozen_string_literal: true

ENV['JWT_PUBLIC_KEY'] = Base64.urlsafe_encode64(OpenSSL::PKey::RSA.generate(512).public_key.to_pem, padding: false)
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
