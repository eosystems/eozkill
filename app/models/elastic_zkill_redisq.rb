class ElasticZkillRedisq
  include ActiveModel::Model

  @client_e = nil
  @client_z = nil

  def initialize
    @client_e = ElasticClient.new
    @client_z = RedisqClient.new(Settings.applications.redisq)
  end


  def loop
    loop_end = false
    begin
      while !loop_end
        response = @client_z.fetch
        if response.items == nil
          loop_end = true
          Rails.logger.info "end"
          next
        end
        r = convert_item(response.items)
        if r != nil
          day_s = response.items["killmail"]["killTime"].to_date.strftime("%Y%m%d").to_s
          index_name =
            "zkill_loss_" + day_s
          begin
            @client_e.create_document(index_name, response.items["killID"], r)
          rescue Elasticsearch::Transport::Transport::Errors::Conflict
            Rails.logger.warn "version conflict:" + response.items["killID"].to_s
          end

          Rails.logger.info "put data:" + day_s.to_s + ":" + response.items["killID"].to_s
        else
          Rails.logger.warn "character id is nil:" + response.items["killID"].to_s
        end
      end
    rescue Exception => e
      Rails.logger.error "error:" + e.to_s
    end


  end

  def convert_item(item)
    solarSystem = SolarSystem.find(item["killmail"]["solarSystem"]["id"])
    region = Region.find(solarSystem.region_id)
    ship = nil
    begin
      ship = Ship.find(item["killmail"]["victim"]["shipType"]["id"])
    rescue Exception => e
      ship = Ship.find(670)
    end

    location = InvItem.find(item["zkb"]["locationID"])
    alliance_name = ""
    alliance_id = ""
    if item["killmail"]["victim"]["alliance"] != nil
      alliance_id =  item["killmail"]["victim"]["alliance"]["id"]
      alliance_name = item["killmail"]["victim"]["alliance"]["name"]
    end

    return nil if item["killmail"]["victim"]["character"] == nil

    j = {
      killID: item["killID"],
      killTime: item["killmail"]["killTime"].to_time,
      regionID: region.id,
      regionName: region.name,
      solarSystemID: solarSystem.id,
      solarSystemName: solarSystem.name,
      security: solarSystem.security,
      securityClass: solarSystem.security_class,
      locationID: item["zkb"]["locationID"],
      locationName: location.name,
      shipTypeID: ship.id,
      shipType: ship.ship_type,
      shipName: ship.ship_name,
      characterID: item["killmail"]["victim"]["character"]["id"],
      characterName: item["killmail"]["victim"]["character"]["name"],
      corporationID: item["killmail"]["victim"]["corporation"]["id"],
      corporationName: item["killmail"]["victim"]["corporation"]["name"],
      allianceID: alliance_id,
      allianceName: alliance_name,
      damageTaken: item["killmail"]["victim"]["damageTaken"],
      totalValue: item["zkb"]["totalValue"],
      points: item["zkb"]["points"],
      npc: item["zkb"]["npc"]
    }
    j.to_json

  end
end
