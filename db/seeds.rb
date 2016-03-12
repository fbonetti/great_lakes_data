STATIONS = [
  {
    id: 1,
    name: 'Milwaukee',
    slug: 'mil',
    latitude: 43.044791,
    longitude: -87.880261
  },
  {
    id: 4,
    name: 'Chicago',
    slug: 'chi',
    latitude: 41.916299,
    longitude: -87.572712
  },
  {
    id: 5,
    name: 'Muskegon',
    slug: 'mkg',
    latitude: 43.226775,
    longitude: -86.339017,
  },
  {
    id: 7,
    name: 'Michigan City',
    slug: 'mcy',
    latitude: 41.729010,
    longitude: -86.911645
  },
  {
    id: 8,
    name: 'South Haven',
    slug: 'shv',
    latitude: 42.401384,
    longitude: -86.288018
  }
]

STATIONS.each do |station_data|
  station = Station.find_or_initialize_by(id: station_data[:id])
  station.attributes = station_data
  station.save(validate: false)
end
