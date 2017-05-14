class ElasticZkill
  include ActiveModel::Model

  @client_e = nil
  @client_z = nil

  def initialize
    @client_e = ElasticClient.new
    @client_z = ZkillClient.new
  end

  def loss_item(item)
    solarSystem = SolarSystem.find(item["solarSystemID"])
    region = Region.find(solarSystem.region_id)
    ship = nil
    begin
      ship = Ship.find(item["victim"]["shipTypeID"])
    rescue Exception => e
      ship = Ship.find(670)
    end

    location = InvItem.find(item["zkb"]["locationID"])
    j = {
      killID: item["killID"],
      killTime: item["killTime"].to_time,
      regionID: region.id,
      regionName: region.name,
      solarSystemID: item["solarSystemID"],
      solarSystemName: solarSystem.name,
      locationID: item["zkb"]["locationID"],
      locationName: location.name,
      shipTypeID: item["victim"]["shipTypeID"],
      shipType: ship.ship_type,
      shipName: ship.ship_name,
      characterID: item["victim"]["characterID"],
      characterName: item["victim"]["characterName"],
      corporationID: item["victim"]["corporationID"],
      corporationName: item["victim"]["corporationName"],
      allianceID: item["victim"]["allianceID"],
      allianceName: item["victim"]["allianceName"],
      damageTaken: item["victim"]["damageTaken"],
      totalValue: item["zkb"]["totalValue"],
      points: item["zkb"]["points"],
      npc: item["zkb"]["npc"]
    }
    j.to_json
  end

  def fetch_by_day(day_s)
    day_start = day_s + "0000"
    day_end = (day_s.to_date + 1).strftime("%Y%m%d").to_s + "0000"

    begin
      delete_index(day_s)
    rescue Exception => e
    end
    create_index(day_s)
    put_mapping(day_s)

    fetch_by_day(day_start, day_end, 10000069, create_loss_index_name(day_s))
  end

  def fetch_by_day_main(day_s)
    day_start = day_s + "0000"
    day_end = (day_s.to_date + 1).strftime("%Y%m%d").to_s + "0000"

    begin
      delete_index(day_s)
    rescue Exception => e
    end
    create_index(day_s)
    put_mapping(day_s)

    fetch_by_day_and_region_id(day_start, day_end, 10000069, create_loss_index_name(day_s))
    fetch_by_day_and_region_id(day_start, day_end, 10000033, create_loss_index_name(day_s))
    fetch_by_day_and_region_id(day_start, day_end, 10000048, create_loss_index_name(day_s))
    fetch_by_day_and_region_id(day_start, day_end, 10000064, create_loss_index_name(day_s))
  end

  def create_loss_index_name(day_s)
    "zkill_loss_" + day_s
  end

  def fetch_by_day_and_region_id(day_start, day_end, region_id, index_name)
    Rails.logger.info("start_region:" + region_id.to_s)
    solar_systems = SolarSystem.where(region_id: region_id)
    solar_systems.each do |solar_system|
      Rails.logger.info("start_solar_system:" + solar_system.name)
      fetch_by_day_and_solar_system_id(day_start, day_end, solar_system.id, index_name)
      Rails.logger.info("end_solar_system:" + solar_system.name)
    end
    Rails.logger.info("end_region:" + region_id.to_s)
  end

  def fetch_by_day_and_solar_system_id(day_start, day_end, solar_system_id, index_name)
    end_flg = false
    page = 1

    while !end_flg
      response = @client_z.fetch_loss_by_day_and_region(day_start, day_end, solar_system_id, page)
      end_flg = true if !response.is_success || response.end_flg
      page = page + 1

      items = response.items
      items.each do |item|
        r = loss_item(item)
        begin
          @client_e.create_document(index_name, item["killID"], r)
          Rails.logger.info("create_document: " + item["killID"].to_s)
        rescue Exception => e
          Rails.logger.warn e.message
        end
      end
    end
  end

  def create_index(date_s)
    @client_e.create_index("zkill_loss_#{date_s}")
  end

  def put_mapping(date_s)
    m = '{
      "properties": {
        "killID" : {
          "type" : "long"
        },
        "killTime" : {
          "type" : "date"
        },
        "regionID" : {
          "type" : "long"
        },
        "regionName" : {
          "index" : "not_analyzed",
          "type" : "text",
            "fields" : {
              "keyword" : {
                "type" : "keyword",
                "ignore_above" : 256
            }
          }
        },
        "solarSystemID" : {
          "type" : "long"
        },
        "solarSystemName" : {
          "index" : "not_analyzed",
          "type" : "text",
            "fields" : {
              "keyword" : {
                "type" : "keyword",
                "ignore_above" : 256
            }
          }
        },
        "locationID" : {
          "type" : "long"
        },
        "locationName" : {
          "index" : "not_analyzed",
          "type" : "text",
            "fields" : {
              "keyword" : {
                "type" : "keyword",
                "ignore_above" : 256
            }
          }
        },
        "shipTypeID" : {
          "type" : "long"
        },
        "shipType" : {
          "index" : "not_analyzed",
          "type" : "text",
            "fields" : {
              "keyword" : {
                "type" : "keyword",
                "ignore_above" : 256
            }
          }
        },
        "shipName" : {
          "index" : "not_analyzed",
          "type" : "text",
            "fields" : {
              "keyword" : {
                "type" : "keyword",
                "ignore_above" : 256
            }
          }
        },
        "characterID" : {
          "type" : "long"
        },
        "charactername" : {
          "index" : "not_analyzed",
          "type" : "text",
            "fields" : {
              "keyword" : {
                "type" : "keyword",
                "ignore_above" : 256
            }
          }
        },
        "corporationID" : {
          "type" : "long"
        },
        "corporationName" : {
          "index" : "not_analyzed",
          "type" : "text",
            "fields" : {
              "keyword" : {
                "type" : "keyword",
                "ignore_above" : 256
            }
          }
        },
        "allianceID" : {
          "type" : "long"
        },
         "allianceName" : {
          "index" : "not_analyzed",
          "type" : "text",
            "fields" : {
              "keyword" : {
                "type" : "keyword",
                "ignore_above" : 256
            }
          }
        },
        "damegeTaken" : {
          "type" : "long"
        },
        "totalValue" : {
          "type" : "long"
        },
        "points" : {
          "type" : "long"
        },
        "npc" : {
          "type" : "boolean"
        }

      }
    }
    '
    @client_e.put_mapping("zkill_loss_#{date_s}", "info", m)
  end

  def delete_index(date_s)
    @client_e.delete("zkill_loss_#{date_s}")
  end
end
