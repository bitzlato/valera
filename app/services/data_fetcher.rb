class DataFetcher
  def self.fetch(market: )
    min_time = 0 # TODO
    query = 'select close from upstream where time > %{min_time} and upstream = %{upstream} and market = %{market}'
    params = { :min_time => min_time, :upstream => :binance, :market => market }
    result = Valera::InfluxDB.client.query(query, :params => params)
    result.first['values'].map do|v|
      # TODO lazy map
      { :date_time => v['time'], :close => v['close'] }
    end
  end
end
