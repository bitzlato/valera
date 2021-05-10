require 'valera/influxdb'
class InfluxWriter
  include Sidekiq::Worker
  include AutoLogger

  #def influx_data
    #{ values:     { id:         id,
                    #price:      price,
                    #amount:     amount,
                    #total:      total,
                    #taker_type: taker_type,
                    #created_at: created_at.to_i },
      #tags:       { market: market.symbol } }
  #end

  def perform(table, values, tags)
    logger.info "Write to #{table} -> #{values} tags: #{tags}"
    values = values
      .symbolize_keys
      .each_with_object({}) { |p, a| a[p.first] = p.last.to_d.to_s == p.last ? p.last.to_d : p.last } # Numerify values
    Valera::InfluxDB
      .client
      .write_point(table, {:values => values, :tags => tags}.symbolize_keys, 'ns')
  end
end
