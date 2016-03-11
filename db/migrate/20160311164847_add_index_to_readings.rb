class AddIndexToReadings < ActiveRecord::Migration
  def change
    remove_column :readings, :id
    add_index :readings, [:station_id, :timestamp], unique: true
  end
end
