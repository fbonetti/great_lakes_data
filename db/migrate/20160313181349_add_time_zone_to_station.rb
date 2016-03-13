class AddTimeZoneToStation < ActiveRecord::Migration
  def change
    add_column :stations, :time_zone, :string
  end
end
