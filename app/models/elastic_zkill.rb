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
    region = Region.find(solarSystem.regionId)
    ship = Ship.find(item["victim"]["shipTypeID"])
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
    binding.pry
    page = 1

    delete_index(day_s)
    create_index(day_s)
    put_mapping(day_s)

    while !end_flg
      response = @client_z.general_fetch("/losses/solarSystemID/30002813/startTime/#{day_start}/endTime/#{day_end}/page/#{page}/no-items/",
                                         current_page: page)
      end_flg = true if !response.is_success || response.end_flg
      page = page + 1
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
          "type" : "string",
          "store" : "yes"
          "index" : "not_alanyzed"
        },
        "solarSystemID" : {
          "type" : "long"
        },
        "solarSystemName" : {
          "type" : "string",
          "store" : "yes",
          "index" : "not_alanyzed"
        },
        "locationID" : {
          "type" : "locationID"
        },
        "locationName" : {
          "type" : "string",
          "store" : "yes",
          "index" : "not_alanyzed"
        },
        "shipTypeID" : {
          "type" : "long
        },
        "shipType" : {
          "type" : "string",
          "store" : "yes",
          "index" : "not_alanyzed"
        },
        "shipName" : {
          "type" : "string",
          "store" : "yes",
          "index" : "not_alanyzed"
        },
        "characterID" : {
          "type" : "long"
        },
        "charactername" : {
          "type" : "string",
          "store" : "yes",
          "index" : "not_alanyzed"
        },
        "corporationID" : {
          "type" : "long"
        },
        "corporationName" : {
          "type" : "string",
          "store" : "yes",
          "index" : "not_alanyzed"
        },
        "allianceID" : {
          "type" : "long"
        },
         "allianceName" : {
          "type" : "string",
          "store" : "yes",
          "index" : "not_alanyzed"
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
          "type" :boolean"
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
