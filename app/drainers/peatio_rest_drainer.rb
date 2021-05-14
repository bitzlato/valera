class PeatioRestDrainer < Drainer
  PERIOD = 1

  def attach
    EM.add_periodic_timer PERIOD do
      market_depth = client.market_depth market.peatio_symbol
      puts market_depth
    end
  end

  private

  def client
    @client ||= PeatioClient.new
  end
end
