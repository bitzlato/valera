# frozen_string_literal: true

require 'faye/websocket'

module Peatio
  module Client
    # Public: Client with methods mirroring the Peatio WebSocket API
    class WebSocket
      attr_reader :base_url

      def initialize(base_url:)
        @base_url = base_url
      end

      # Public: Create multiple WebSocket streams
      #
      # :streams - The Array of Array (scope + stream name)
      #
      # :methods - The Hash which contains the event handler methods to pass to
      #            the WebSocket client
      #   :open    - The Proc called when a stream is opened (optional)
      #   :message - The Proc called when a stream receives a message
      #   :error   - The Proc called when a stream receives an error (optional)
      #   :close   - The Proc called when a stream is closed (optional)
      def multi(streams:, methods:)
        streams
          .each_with_object({ private: [], public: [] }) { |stream, o| o[stream.first] << stream.second }
          .each_pair do |scope, names|
          next if names.empty?

          query = URI.encode_www_form(names.map { |stream| [:stream, stream] })
          create_stream("#{base_url}/#{scope}/?#{query}", methods: methods)
        end
      end

      private

      # Internal: Initialize and return a Faye::WebSocket::Client
      #
      # url - The String url that the WebSocket should try to connect to
      #
      # :methods - The Hash which contains the event handler methods to pass to
      #            the WebSocket client
      #   :open    - The Proc called when a stream is opened (optional)
      #   :message - The Proc called when a stream receives a message
      #   :error   - The Proc called when a stream receives an error (optional)
      #   :close   - The Proc called when a stream is closed (optional)
      def create_stream(url, methods:)
        Faye::WebSocket::Client.new(url, '', ping: 1000)
                               .tap { |ws| attach_methods(ws, methods) }
      end

      # Internal: Iterate through methods passed and add them to the WebSocket
      #
      # websocket - The Faye::WebSocket::Client to apply methods to
      #
      # methods - The Hash which contains the event handler methods to pass to
      #   the WebSocket client
      #   :open    - The Proc called when a stream is opened (optional)
      #   :message - The Proc called when a stream receives a message
      #   :error   - The Proc called when a stream receives an error (optional)
      #   :close   - The Proc called when a stream is closed (optional)
      def attach_methods(websocket, methods)
        methods.each_pair do |key, method|
          websocket.on(key) { |event| method.call(event) }
        end
      end
    end
  end
end
