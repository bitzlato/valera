# frozen_string_literal: true

# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

module Huobi
  class Websocket < Faye::WebSocket::Client
    class Error < StandardError; end

    URL = 'wss://api.huobi.pro/ws'
    PING = 3

    def initialize
      super URL, [], ping: PING
      @request_id = 0
    end

    def market_ticker!(symbol)
      subscribe "market.#{symbol}.ticker"
    end

    def multi(streams:, methods:)
      streams.each do |stream|
        subscribe stream
      end
      methods.each_pair do |key, method|
        on(key) do |event|
          catch :ignoreMessage do
            method.call(process_event(event))
          end
        end
      end
    end

    private

    def process_event(event)
      case event
      when Faye::WebSocket::API::ErrorEvent
        raise Error, event
      when Faye::WebSocket::API::OpenEvent, Faye::WebSocket::API::CloseEvent
        event
      else
        message = Zlib::GzipReader.new(StringIO.new(event.data.pack('C*'))).read
        data = JSON.parse(message, symbolize_names: true)
        if data[:ping]
          send({ pong: data.fetch(:ping) }.to_json)
          throw :ignoreMessage

        elsif data[:error]
          raise Error, "(#{data[:code]}) #{data[:msg]}"

        elsif data.key? :status
          raise Error, data if data[:status] == 'error'

          throw :ignoreMessage

        else
          data
        end
      end
    end

    def request_id
      @request_id += 1
    end

    def subscribe(stream)
      send({ sub: stream, id: request_id }.to_json)
    end

    # Terminating socket connection achieves the same result.
    # If you have a use-case for this, please create a GitHub issue.
    #
    # def unsubscribe(streams)
    #   send({
    #     method: "UNSUBSCRIBE",
    #     params: streams,
    #     id: request_id,
    #   }.to_json)
    # end
  end
end
