namespace :import do
  desc "TODO"
  task archived_data: :environment do
    Station.all.each do |station|
      year = 2015
      puts "Importing data for station: #{station.name}, year: #{year}"
      DataImporter.import(station, year)
    end
  end
end
