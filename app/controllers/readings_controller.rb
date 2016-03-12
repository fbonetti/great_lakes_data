class ReadingsController < ApplicationController
  def index
    stations = Station.all.map do |station|
      station.attributes.slice('id', 'name', 'latitude', 'longitude')
    end
    @elm_data = { stations: stations }
  end

  def daily_average
    sql = "
      SELECT extract(epoch from timestamp::date) * 1000 as date, avg(wind_speed) * 1.94384 AS avg_knots
      FROM readings
      WHERE station_id = :station_id
      AND timestamp >= :start_date
      AND timestamp <= :end_date
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