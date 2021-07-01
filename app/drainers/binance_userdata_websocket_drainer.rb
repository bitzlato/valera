
# Copyright (c) 2019 Danil Pismenny <danil@brandymint.ru>

# frozen_string_literal: true

# Connects to binance stream and store kline to internal influx
#
class BinanceUserdataWebsocketDrainer < WebsocketDrainer
  def initialize(id: , account:)
    raise 'Account must be present' if account.nil?

    super(id: id, account: account)
  end

  # Attach to web sockets
  def attach
    logger.info "Attach userdata streams"
    SdNotify.status('Drainer attach')
    ws_client.user_data listen_key: listen_key, methods: methods
  end

  def message(event)
    SdNotify.status('Drainer message')
    data = JSON.parse(event.data)

    case data['e']
    when 'outboundAccountPosition'
      outboundAccountPosition(data)
    when 'executionReport'
      executionReport(data)
    else
      logger.warn "Unknown event #{data}"
    end
  end

  private

  # {"e"=>"outboundAccountPosition",
  # "E"=>1625132433497,  //Event Time
  # "u"=>1625132433496,  //Time of last account update
  # "B"=> //Balances Array
  # [{"a"=>"BTC", "f"=>"0.02645391", "l"=>"0.00000000"}, {"a"=>"BNB", "f"=>"0.00000000", "l"=>"0.00000000"}, {"a"=>"USDT", "f"=>"737.39081412", "l"=>"0.00000000"}]}
  def outboundAccountPosition(data)
    logger.debug(data)

    balances = data['B'].each_with_object(ActiveSupport::HashWithIndifferentAccess.new) do |r, a|
      a[r.fetch('a')] = { available: r['f'], locked: r['l'] }
    end

    binding.pry
    # TODO sync update
    #
    account.update_attributes!(
      balances_updated_at: Time.at(data['E']/1000),
      balances: account.reload.balances.merge(balances)
    )
  end

  #=> {"e"=>"executionReport",
      #"E"=>1625132433497,
      #"s"=>"BTCUSDT",
      #"c"=>"rZ1H7KlI9acsnSP0Nt2SoQ",
      #"S"=>"BUY",
      #"o"=>"LIMIT",
      #"f"=>"IOC",
      #"q"=>"0.01000000",
      #"p"=>"33350.00000000",
      #"P"=>"0.00000000",
      #"F"=>"0.00000000",
      #"g"=>-1,
      #"C"=>"",
      #"x"=>"NEW",
      #"X"=>"NEW",
      #"r"=>"NONE",
      #"i"=>6701676478,
      #"l"=>"0.00000000",
      #"z"=>"0.00000000",
      #"L"=>"0.00000000",
      #"n"=>"0",
      #"N"=>nil,
      #"T"=>1625132433496,
      #"t"=>-1,
      #"I"=>14322953735,
      #"w"=>true,
      #"m"=>false,
      #"M"=>false,
      #"O"=>1625132433496,
      #"Z"=>"0.00000000",
      #"Y"=>"0.00000000",
      #"Q"=>"0.00000000"}
  def executionReport(data)
    logger.debug(data)
  end

  # TODO expire after a hour
  def listen_key
    @listen_key ||= account.client.client.listen_key['listenKey']
  end

  def ws_client
    @client ||= Binance::Client::WebSocket.new
  end
end
