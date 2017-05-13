class ElasticZkill
  include ActiveModel::Model

  @client_e = nil
  @client_z = nil

  def initialize
    @client_e = ElasticClient.new
    @client_z = ZkillClient.new
  end

  def fetch_loss(url)
    r = @client_z.general_fetch(url)
  end

  def sample
    @client_z.general_fetch("/losses/regionID/10000002/")
  end

  def sample2
    response = @client_z.general_fetch("/losses/regionID/10000069/")
    binding.pry
    response.items.each do |item|
      begin
        @client_e.create_document("zkill", item["killID"], item)
      rescue Exception => e
        Rails.logger.warn e.message
      end
    end
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
      killTime: item["killTime"],
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

    end_flg = false
    page = 1

    begin
      delete_index(day_s)
    rescue Exception => e
    end
    create_index(day_s)

    put_mapping(day_s)

    while !end_flg
      response = @client_z.general_fetch("/losses/solarSystemID/30002813/startTime/#{day_start}/endTime/#{day_end}/page/#{page}/no-items/",
                                         current_page: page)
      end_flg = true if !response.is_success || response.end_flg
      page = page + 1

      items = response.items
      items.each do |item|
        r = loss_item(item)
        begin
          @client_e.create_document("zkill_loss_#{day_s}", item["killID"], r)
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
          "type" : "date",
          "store" : "yes",
          "format" : "YYYY-mm-dd HH:mm:ss"
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
