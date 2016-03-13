class ReadingsController < ApplicationController
  def index
    stations = Station.all.map do |station|
      station.attributes.slice('id', 'name', 'latitude', 'longitude')
      {
        id: station.id,
        name: station.name,
        latitude: station.latitude,
        longitude: station.longitude,
        minTimestamp: station.readings.minimum(:timestamp).to_i,
        maxTimestamp: station.readings.maximum(:timestamp).to_i
      }
    end
    
    @elm_data = { stations: stations }
  end

  # def station_data
  #   daily_average = query_daily_average
  # end

  def daily_average
    sql = "
      SELECT extract(epoch from (timestamp::timestamp at time zone stations.time_zone)::date) * 1000 as date,
             avg(wind_speed) * 1.94384 AS avg_knots
      FROM readings
      JOIN stations ON stations.id = station_id
      WHERE station_id = :station_id
      AND timestamp >= to_timestamp(:start_date)
      AND timestamp <= to_timestamp(:end_date)
      GROUP BY date
      ORDER BY date
    "

    values = params.slice(:station_id, :start_date, :end_date)
    results = select_rows(sql, values).map do |row|
      [row[0].to_i, row[1].to_f]
    end

    render json: results
  end

  private

  def sanitize_sql(sql, values = {})
    ActiveRecord::Base.send(:sanitize_sql, [sql, values], '')
  end

  def select_rows(sql, values = {})
    ActiveRecord::Base.connection.select_rows(sanitize_sql(sql, values))
  end
end