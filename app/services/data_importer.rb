require 'open-uri'

class DataImporter
  def self.import(station, year)
    uri = URI::HTTP.build(
      host: 'www.glerl.noaa.gov',
      path: "/metdata/#{station.slug}/archive/#{station.slug}#{year}.#{station.id.to_s.rjust(2, '0')}t.txt"
    )
    open(uri) do |file|
      inserts = file.map { |row| convert_row_to_sql_insert(row) }.compact
      insert_readings(inserts)
    end
  end

  private

  def self.convert_row_to_sql_insert(row)
    return nil if row.include?("ID") || row.include?("AirTemp")

    data = row.split(" ")

    station_id = data[0]
    year = data[1]
    day_of_year = data[2]
    utc_time = data[3]
    air_temp = data[4]
    wind_speed = data[5]
    wind_gust = data[6]
    wind_direction = data[7]

    timestamp = DateTime.strptime([year, day_of_year, utc_time].join(' '), "%Y %j %H%M").to_s

    values = {
      station_id: station_id,
      timestamp: timestamp,
      air_temp: air_temp,
      wind_speed: wind_speed,
      wind_gust: wind_gust,
      wind_direction: wind_direction
    }

    return nil if wind_speed.to_f < 0 || wind_gust.to_f < 0 || wind_direction.to_i < 0

    sql = "(:station_id, :timestamp, :air_temp, :wind_speed, :wind_gust, :wind_direction)"
    sanitize(sql, values)
  end

  def self.insert_readings(inserts)
    ActiveRecord::Base.connection.execute("
      INSERT INTO readings (station_id, timestamp, air_temp, wind_speed, wind_gust, wind_direction)
      VALUES #{inserts.join(', ')}
      ON CONFLICT DO NOTHING
    ")
  end

  def self.sanitize(sql, values = {})
    ActiveRecord::Base.send(:sanitize_sql, [sql, values], '')
  end
end