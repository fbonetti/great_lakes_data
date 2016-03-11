STATIONS = [
  {
    id: 4,
    name: 'Chicago',
    latitude: 41.92,
    longitude: -87.6
  },
  {
    id: 8,
    name: 'South Haven',
    latitude: 42.401384,
    longitude: -86.288018
  }
]

Station.delete_all
STATIONS.each do |station_data|
  Station.create(station_data)
end
