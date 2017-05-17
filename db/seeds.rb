require "csv"

Ship.delete_all
CSV.foreach('data/ships.csv') do |row|
  Ship.create(:id => row[0], :ship_type => row[1], :ship_name => row[2])
end

Region.delete_all
header = true
CSV.foreach('data/mapRegions.csv') do |row|
  if header
    header = false
    next
  end
  Region.create(
    :id => row[0],
    :name => row[1],
  )
end

SolarSystem.delete_all
header = true
CSV.foreach('data/mapSolarSystems.csv') do |row|
  if header
    header = false
    next
  end
  SolarSystem.create(
    :id => row[2],
    :region_id => row[0],
    :name => row[3],
  )
end

COMMIT_COUNT = 5000
results = []
count = 0
InvItem.delete_all
header = true
CSV.foreach('data/invNames.csv') do |row|
  if header
    header = false
    next
  end
  r = InvItem.new(
    :id => row[0],
    :name => row[1],
    :security => row[21],
    :security_class => row[25]
  )
  results << r
  if count % COMMIT_COUNT == 0
    InvItem.import results
    results = []
  end
  count = count + 1
end

InvItem.import results
