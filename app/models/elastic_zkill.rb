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
    response = @client_z.general_fetch("/losses/regionID/10000002/")
    binding.pry
    response.items.each do |item|
      begin
        @client_e.create_document("zkill", item["killID"], item)
      rescue Exception => e
        Rails.logger.warn e.message
      end
    end
  end

  def create_index
    @client_e.create_index("zkill_loss")
  end

  def put_mapping
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
    @client_e.put_mapping("zkill", "info", m)
  end

  def delete_index
    @client_e.delete("zkill")
  end
end
