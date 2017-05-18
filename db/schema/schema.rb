## Master ##
create_table :ships, collate: "utf8_bin" do |t|
  t.int :id, primary_key: true, extra: :auto_increment
  t.varchar :ship_type
  t.varchar :ship_name
end

create_table :inv_items, collate: "utf8_bin" do |t|
  t.int :id, primary_key: true, extra: :auto_increment
  t.varchar :name
end

create_table :regions, collate: "utf8_bin" do |t|
  t.int :id, primary_key: true, extra: :auto_increment
  t.varchar :name
end

create_table :solar_systems, collate: "utf8_bin" do |t|
  t.int :id, primary_key: true, extra: :auto_increment
  t.int :region_id
  t.varchar :name
  t.decimal :security, null: true, precision: 20, scale: 4
  t.varchar :security_class, null: true
end

create_table :system_counts, collate: "utf8_bin" do |t|
  t.int :id, primary_key: true, extra: :auto_increment
end


