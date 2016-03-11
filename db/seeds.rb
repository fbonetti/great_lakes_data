STATIONS = [
  {
    id: 4,
    name: 'Chicago',
    latitude: 41.92,
    longitude: -87.6
  }
]

Station.delete_all
STATIONS.each do |station_data|
  Station.create(station_data)
end