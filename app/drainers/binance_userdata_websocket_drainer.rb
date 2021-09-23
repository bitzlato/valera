# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

# Connects to binance stream and store kline to internal influx
#
class BinanceUserdataWebsocketDrainer < WebsocketDrainer
  KEYS = []

  def initialize(id:, account:)
    raise 'Account must be present' if account.nil?

    super(id: id, account: account)
  end

  # Attach to web sockets
  def attach
    logger.info 'Attach userdata streams'
    SdNotify.status('Drainer attach')
    ws_client.user_data listen_key: listen_key, methods: methods
  end

  def message(event)
    SdNotify.status('Drainer message')
    data = JSON.parse(event.data)

    case data['e']
    when 'outboundAccountPosition'
      update_account(data)
    when 'executionReport'
      save_execution(data)
    else
      logger.warn "Unknown event #{data}"
    end
  end

  private

  # {"e"=>"outboundAccountPosition",
  # "E"=>1625132433497,  //Event Time
  # "u"=>1625132433496,  //Time of last account update
  # "B"=> //Balances Array
  # [{"a"=>"BTC", "f"=>"0.02645391", "l"=>"0.00000000"},
  # {"a"=>"BNB", "f"=>"0.00000000", "l"=>"0.00000000"},
  # {"a"=>"USDT", "f"=>"737.39081412", "l"=>"0.00000000"}]}
  def update_account(data)
    logger.debug(data)

    balances = data['B'].each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |r, a|
      a[r.fetch('a')] = { available: r['f'], locked: r['l'] }
    end

    # TODO: sync update
    #
    account.update_attributes!(
      balances_updated_at: Time.at(data['E'] / 1000),
      balances: account.reload.balances.merge(balances)
    )
  end

  def save_execution(data)
    logger.debug(data)
  end

  # TODO: expire after a hour
  def listen_key
    @listen_key ||= account.client.client.listen_key['listenKey']
  end

  def ws_client
    @ws_client ||= Binance::Client::WebSocket.new
  end
end
