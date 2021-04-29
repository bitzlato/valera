require 'openssl'
class PeatioClient
  class Error < StandardError; end
  WrongResponse = Class.new Error

  def initialize(access_key: ENV['PEATIO_API_ACCESS_KEY'], secret_key: ENV['PEATIO_API_SECRET_KEY'], endpoint: ENV['PEATIO_ENDPOINT'], prefix: '/api/v2/peatio')
    @access_key = access_key
    @secret_key = secret_key
    @endpoint = endpoint
    @prefix = prefix
  end
  # puts PeatioAPI::Client.new(endpoint: ENTPOINT).get_public('/api/v2/peatio/public/markets/tickers')
  # puts client.get '/api/v2/peatio/orders', market: 'ethbtc'

  def account_balances
    get('/account/balances')
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

  #optional :market,
  #optional :base_unit,
  #optional :quote_unit,
  #optional :state,
  #optional :limit,
  #optional :page,
  #optional :order_by,
  #optional :ord_type,
  #optional :type,
  #optional :time_from,
  #optional :time_to,
  def orders(params = {})
    get '/market/orders', params
  end

  def cancel_order(order_id)
    post "/market/orders/#{order_id}/cancel"
  end

  def cancel_orders(params = {})
    post '/market/orders/cancel', params
  end

  def post(path, params = {})
    parse_response connection.post prefix + path, params.to_json
  end

  def get(path, params = {})
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
        'X-Auth-Signature' => OpenSSL::HMAC.hexdigest("SHA256", secret_key, nonce + access_key)
      }
      if ENV.true? 'CURL_LOGGER'
        c.use Faraday::Response::Logger
        c.request :curl, logger, :warn
      end
    end
  end

  def parse_response(response)
    raise WrongResponse, "Wrong response status (#{response.status}) with body '#{response.body}'" unless response.success?
    return nil if response.body.empty?
    raise WrongResponse, "Wrong content type (#{response['content-type']})" if response['content-type'] != 'application/json'
    JSON.parse response.body
  end

  def logger
    Logger.new(STDOUT)
  end
end
