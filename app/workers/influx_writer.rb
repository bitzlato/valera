require 'valera/influxdb'
class InfluxWriter
  include Sidekiq::Worker

  #def influx_data
    #{ values:     { id:         id,
                    #price:      price,
                    #amount:     amount,
                    #total:      total,
                    #taker_type: taker_type,
                    #created_at: created_at.to_i },
      #tags:       { market: market.symbol } }
  #end

  def perform(table, data)
    Valera::InfluxDB
      .client
      .write_point(table, data, "ns")
  end
end
