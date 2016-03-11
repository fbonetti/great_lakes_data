class CreateStations < ActiveRecord::Migration
  def change
    create_table :stations do |t|
      t.string :name
      t.float :latitude
      t.float :longitude
    end
  end
end
