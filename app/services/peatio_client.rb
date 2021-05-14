# frozen_string_literal: true

require 'openssl'
# puts PeatioAPI::Client.new(endpoint: ENTPOINT).get_public('/api/v2/peatio/public/markets/tickers')
# puts client.get '/api/v2/peatio/orders', market: 'ethbtc'

class PeatioClient
  class Error < StandardError; end
  WrongResponse = Class.new Error

  attr_reader :name

  def initialize(name: nil,
                 access_key: ENV['PEATIO_API_ACCESS_KEY'],
                 secret_key: ENV['PEATIO_API_SECRET_KEY'],
                 endpoint: ENV['PEATIO_ENDPOINT'],
                 prefix: '/api/v2/peatio')
    @access_key = access_key || raise('No access_key')
    @secret_key = secret_key || raise('No secret_key')
    @endpoint = endpoint || raise('No endpoint')
    @prefix = prefix || raise('No prefix')
    @name = name
  end

  def to_s
    name
  end

  def account_balances(currency = nil)
    if currency.present?
      get("/account/balances/#{currency}")
    else
      get('/account/balances')
    end
  end

  def markets
    get('/public/markets')
  end

  # market
  # ord_type = [market, limit] default is limit
  # price = require if ord_type == limit
  # side = [sell, buy] (OrderAsk, OrderBid)
  # volume
  def create_order(order)
    post '/market/orders', order
  end

  # optional :market,
  # optional :base_unit,
  # optional :quote_unit,
  # optional :state,
  # optional :limit,
  # optional :page,
  # optional :order_by,
  # optional :ord_type,
  # optional :type,
  # optional :time_from,
  # optional :time_to,
  def orders(params = {})
    get '/market/orders', params
  end

  def cancel_order(order_id)
    post "/market/orders/#{order_id}/cancel"
  end

  # @param optional Hash with keys: market, side
  def cancel_orders(params = {})
    post '/market/orders/cancel', params
  end

  def order_book(market, params = {})
    get "/public/markets/#{market}/order-book", params
  end

  def market_depth(market)
    get "/public/markets/#{market}/depth"
  end

  def post(path, params = {})
    parse_response connection.post prefix + path, params.to_json
  end

  def get(path, params = {})
    puts prefix + path
    parse_response connection.get prefix + path, params
  end

  private

  attr_reader :access_key, :secret_key, :endpoint, :prefix

  def connection
    nonce = (Time.now.to_f * 1000).to_i.to_s
    Faraday.new url: endpoint do |c|
      c.headers = {
        'Content-Type' => 'application/json',
        'Accept' => 'application/json',
        'X-Auth-Apikey' => access_key,
        'X-Auth-Nonce' => nonce,
        'X-Auth-Signature' => OpenSSL::HMAC.hexdigest('SHA256', secret_key, nonce + access_key)
      }
      c.adapter Faraday.default_adapter
      c.response :logger if ENV.true? 'FARADAY_LOGGER'
      if ENV.true? 'CURL_LOGGER'
        c.use Faraday::Response::Logger
        c.request :curl, logger, :warn
      end
    end
  end

  def parse_response(response)
    unless response.success?
      raise WrongResponse,
            "Wrong response status (#{response.status}) with body '#{response.body}' for #{name}"
    end
    return nil if response.body.empty?

    if response['content-type'] != 'application/json'
      raise WrongResponse,
            "Wrong content type (#{response['content-type']}) for #{name}"
    end

    JSON.parse response.body
  end

  def logger
    Logger.new($stdout)
  end
end
