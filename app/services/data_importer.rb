require 'open-uri'

class DataImporter
  def self.import
    open(URI("http://www.glerl.noaa.gov/metdata/chi/archive/chi2015.04t.txt")) do |file|
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