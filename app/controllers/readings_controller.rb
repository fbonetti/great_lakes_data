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

  def station_data
    render json: {
      daily_average_data: query_daily_average_data,
      wind_rose_data: query_wind_rose_data
    }
  end

  private

  def sanitize_sql(sql, values = {})
    ActiveRecord::Base.send(:sanitize_sql, [sql, values], '')
  end

  def select_rows(sql, values = {})
    ActiveRecord::Base.connection.select_rows(sanitize_sql(sql, values))
  end

  def select_value(sql, values = {})
    ActiveRecord::Base.connection.select_value(sanitize_sql(sql, values))
  end

  def query_daily_average_data
    # SELECT extract(epoch from (timestamp::timestamp at time zone stations.time_zone)::date) * 1000 as date,
    sql = "
      SELECT extract(epoch from timestamp::date) * 1000 as date,
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
    select_rows(sql, values).map do |row|
      [row[0].to_i, row[1].to_f]
    end
  end

  def query_wind_rose_data
    total_count_sql = "
      SELECT COUNT(*)
      FROM readings
      WHERE station_id = :station_id
      AND timestamp BETWEEN to_timestamp(:start_date) AND to_timestamp(:end_date)
    "

    wind_rose_sql = "
      SELECT
        (ROUND(wind_direction / 22.5) * 22.5) % 360 AS cardinal_direction,
        COUNT(CASE WHEN (wind_speed * 1.94384) < 5 THEN TRUE ELSE NULL END)::float / :total * 100,
        COUNT(CASE WHEN (wind_speed * 1.94384) BETWEEN 5 AND 10 THEN TRUE ELSE NULL END)::float / :total * 100,
        COUNT(CASE WHEN (wind_speed * 1.94384) BETWEEN 10 AND 15 THEN TRUE ELSE NULL END)::float / :total * 100,
        COUNT(CASE WHEN (wind_speed * 1.94384) BETWEEN 15 AND 20 THEN TRUE ELSE NULL END)::float / :total * 100,
        COUNT(CASE WHEN (wind_speed * 1.94384) BETWEEN 20 AND 25 THEN TRUE ELSE NULL END)::float / :total * 100,
        COUNT(CASE WHEN (wind_speed * 1.94384) > 25 THEN TRUE ELSE NULL END)::float / :total * 100
      FROM readings
      WHERE station_id = :station_id
      AND timestamp BETWEEN to_timestamp(:start_date) AND to_timestamp(:end_date)
      GROUP BY cardinal_direction
      ORDER BY cardinal_direction
    "

    values = params.slice(:station_id, :start_date, :end_date)
    total = select_value(total_count_sql, values)
    rows = select_rows(wind_rose_sql, values.merge(total: total))
    rows.transpose[1..-1].map { |r| r.map { |x| x.to_f.round(1) } }
  end
end