class CreateReadings < ActiveRecord::Migration
  def change
    create_table :readings do |t|
      t.integer :station_id, null: false
      t.datetime :timestamp
      t.float :air_temp
      t.float :wind_speed
      t.float :wind_gust
      t.integer :wind_direction
    end

    add_index :readings, :station_id
  end
end
