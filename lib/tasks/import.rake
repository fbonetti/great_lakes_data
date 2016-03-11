require 'csv'

namespace :import do
  desc "TODO"
  task import_data: :environment do
    raw_data = Net::HTTP.get(URI("http://www.glerl.noaa.gov/metdata/chi/archive/chi2015.04t.txt"))

    rows = raw_data.split("\n").reject { |line| line.include?("ID") || line.include?("AirTemp") }
    tempfile = Tempfile.new(['2015_clean_data', '.csv'])

    CSV.open(tempfile, 'w') do |csv|
      rows.each do |row|
        data = row.split(" ")

        station_id = data[0]
        year = data[1]
        day_of_year = data[2]
        utc_time = data[3]
        air_temp = data[4]
        wind_speed = data[5]
        wind_gust = data[6]
        wind_dir = data[7]

        timestamp = DateTime.strptime([year, day_of_year, utc_time].join(' '), "%Y %j %H%M").to_s

        csv << [station_id, timestamp, air_temp, wind_speed, wind_gust, wind_dir]
      end
    end

    ActiveRecord::Base.connection.execute("DELETE FROM readings")
    ActiveRecord::Base.connection.execute("
      COPY readings (station_id, timestamp, air_temp, wind_speed, wind_gust, wind_direction)
      FROM '#{tempfile.path}'
      DELIMITER ',' CSV
    ")
  end
end
