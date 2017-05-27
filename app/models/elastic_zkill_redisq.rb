class ElasticZkillRedisq
  include ActiveModel::Model

  @client_e = nil
  @client_z = nil

  def initialize
    @client_e = ElasticClient.new
    @client_z = RedisqClient.new(Settings.applications.redisq)
  end


  def loop
    return if SystemCount.count > 0

    SystemCount.new.save!

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
          # ゴミデータでESエラーがでるのを防ぐ
          if day_s < (Time.now.to_date - 3).strftime("%Y%m%d").to_s
            Rails.logger.warn "mayby error data. ignore:" + day_s
            next
          end

          begin
            @client_e.create_document(index_name, response.items["killID"], r.to_json)
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
      Rails.logger.error "error:" + e.backtrace.join("\n")
    end

    SystemCount.delete_all

  end

  def convert_item(item)
    solarSystem = SolarSystem.find(item["killmail"]["solarSystem"]["id"])
    region = Region.find(solarSystem.region_id)
    ship = nil
    begin
      ship = Ship.find(item["killmail"]["victim"]["shipType"]["id"])
    rescue ActiveRecord::RecordNotFound
      Ship.new(
        id: item["killmail"]["victim"]["shipType"]["id"],
        ship_type: item["killmail"]["victim"]["shipType"]["name"],
        ship_name: item["killmail"]["victim"]["shipType"]["name"]
      ).save
      ship = Ship.find(item["killmail"]["victim"]["shipType"]["id"])
      Rails.logger.info("create new ship:" + ship.id.to_s)
   end

    location = InvItem.find(item["zkb"]["locationID"])
    alliance_name = ""
    alliance_id = ""
    if item["killmail"]["victim"]["alliance"] != nil
      alliance_id =  item["killmail"]["victim"]["alliance"]["id"]
      alliance_name = item["killmail"]["victim"]["alliance"]["name"]
    else
      alliance_id = 0
      alliance_name = ""
    end

    return nil if item["killmail"]["victim"]["character"] == nil
    # Attackers
    attackers = []
    item["killmail"]["attackers"].to_a.each do |ar|
      if ar["shipType"] != nil
        a_ship_id = ar["shipType"]["id"]

        begin
          a_ship = Ship.find(ar["shipType"]["id"])
        rescue ActiveRecord::RecordNotFound
          Ship.new(
            id: ar["shipType"]["id"],
            ship_type: ar["shipType"]["name"],
            ship_name: ar["shipType"]["name"]
          ).save
          a_ship = Ship.find(ar["shipType"]["id"])
          Rails.logger.info("create new ship:" + a_ship.to_s)
        end

        tmp = {
          shipName: a_ship.ship_name,
          shipTypeID: a_ship.id,
          shipType: a_ship.ship_type,
          characterID: ar["character"].present? ? ar["character"]["id"] : 0,
          characterName: ar["character"].present? ? ar["character"]["name"] : "",
          corporationID: ar["corporation"].present? ? ar["corporation"]["id"] : 0,
          corporationName: ar["corporation"].present? ? ar["corporation"]["name"] : "",
          allianceID: ar["alliance"].present? ? ar["alliance"]["id"] : 0,
          allianceName: ar["alliance"].present? ? ar["alliance"]["name"] : "",
          damageDone: ar["damageDone"].to_i
        }
        attackers.push(tmp)
      end
    end

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
      totalValue: item["zkb"]["totalValue"].to_i,
      points: item["zkb"]["points"],
      npc: item["zkb"]["npc"],
      attackerCount: item["killmail"]["attackerCount"].to_i,
      attackers: attackers
    }
  end

  #def convert_item2(item, a_item)
  #  r = item
  #  r.delete("shipTypeID")
  #  r.delete("shipName")
  #  r.delete("characterID")
  #  r.delete("characterName")
  #  r.delete("corporationID")
  #  r.delete("corporationName")
  #  r.delete("allianceID")
  #  r.delete("allianceName")
  #  r.delete("damageTaken")
  #  r.delete("points")
  #end


end
