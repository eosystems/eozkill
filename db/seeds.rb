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

InvItem.delete_all
header = true
CSV.foreach('data/invNames.csv') do |row|
  if header
    header = false
    next
  end
  InvItem.create(
    :id => row[0],
    :name => row[1],
  )
end

