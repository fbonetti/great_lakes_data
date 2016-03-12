# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20160312163943) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "readings", id: false, force: :cascade do |t|
    t.integer  "station_id",     null: false
    t.datetime "timestamp"
    t.float    "air_temp"
    t.float    "wind_speed"
    t.float    "wind_gust"
    t.integer  "wind_direction"
  end

  add_index "readings", ["station_id", "timestamp"], name: "index_readings_on_station_id_and_timestamp", unique: true, using: :btree
  add_index "readings", ["station_id"], name: "index_readings_on_station_id", using: :btree

  create_table "stations", force: :cascade do |t|
    t.string "name"
    t.float  "latitude"
    t.float  "longitude"
    t.string "slug"
  end

end
