namespace :import do
  desc "TODO"
  task import_data: :environment do
    DataImporter.import
  end
end
