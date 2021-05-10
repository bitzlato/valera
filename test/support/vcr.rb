# frozen_string_literal: true

# Source: https://gist.github.com/mattbrictson/72910465f36be8319cde
#
require 'vcr'

VCR.configure do |config|
  config.allow_http_connections_when_no_cassette = false
  config.cassette_library_dir = 'test/cassettes'
  config.hook_into :webmock
  config.ignore_request { ENV['DISABLE_VCR'] }
  config.ignore_localhost = true
  config.default_cassette_options = {
    record: :new_episodes
  }
  %w[PEATIO_ENDPOINT PEATIO_API_ACCESS_KEY PEATIO_API_SECRET_KEY].each do |key|
    config.filter_sensitive_data("<#{key}>") { ENV[key] }
  end
end

module ActiveSupport
  class TestCase
    # Add more helper methods to be used by all tests here...
    def self.test(test_name, &block)
      return super if block.nil?

      cassette = [name, test_name].map do |str|
        str.underscore.gsub(/[^A-Z]+/i, '_')
      end.join('/')

      # will automatically use VCR to intercept and record/play back any external
      # HTTP requests using `cassettes/order_test/_user_can_place_order.yml`.
      super(test_name) do
        VCR.use_cassette(cassette) do
          instance_eval(&block)
        end
      end
    end
  end
end
