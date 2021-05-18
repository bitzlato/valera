# frozen_string_literal: true

class WebsocketDrainer < Drainer
  # Attach to web sockets
  def attach
    logger.info "Attach streams #{streams}"
    SdNotify.status('Drainer attach')
    client.multi(streams: streams, methods: methods)
  end

  def open(event)
    SdNotify.status('Drainer open')
    dump_headers event
  end

  def error(event)
    # Possible event.message:
    # Errno::ECONNRESET
    Bugsnag.notify event.message do |b|
      b.meta_data = { market_id: market.id }
    end
    logger.error "Error (#{event.type}) with message #{event.message}"

    if event.message == Errno::ECONNRESET
      logger.warn 'Reattach'
      attach
    end
  end

  def close(event = nil)
    dump_headers event
    logger.warn "Closed connection with code #{event.code}, stop strategies #{market.strategies.map(&:to_s)}"
  end

  def message(event)
    SdNotify.status('Drainer message')
    dump_headers event
    data = JSON.parse(event.data)
    logger.debug data if ENV.true? 'DEBUG_WEBSOCKET_MESSAGE'

    catch :ignoreMessage do
      update! map data
    end
  end

  private

  def map(_data)
    raise 'not implemented'
  end

  def streams
    raise 'not implemented'
  end

  def methods
    %i[open message error close].each_with_object({}) do |m, a|
      a[m] = method m
    end
  end

  def client
    raise 'not implemented'
  end

  def dump_headers(event)
    logger.debug event.target.headers.inspect if ENV.true? 'DUMP_WEBSOCKET_HEADERS'
  end
end
