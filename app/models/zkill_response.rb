class ZkillResponse
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  attr_accessor *%i(
    is_success victim attackers killID killTime zkb items end_flg
  )

  def self.parse(response, current_page: 1)
    new.tap do |r|
      b = Zlib::GzipReader.new(StringIO.new(response.body)).read
      body = JSON.parse(b)
      header = response.headers
      r.is_success = response.success?
      if body != ""
        r.victim = HashObject.new(body[0]['victim'])
        r.attackers = body[0]['attackers'].map { |v| HashObject.new(v) }
        r.items = body[0]['items'].map { |v| HashObject.new(v) }
        r.killID = body[0]['killID']
        r.killTime = body[0]['killTime']
        r.zkb = HashObject.new(body[0]['zkb'])
      end
    end
  end

  def self.parse_j(response, current_page: 1)
    new.tap do |r|
      b = Zlib::GzipReader.new(StringIO.new(response.body)).read
      body = JSON.parse(b)
      header = response.headers
      r.is_success = response.success?
      if body != ""
        r.items = body
      end
      if r.items.count < 200
        r.end_flg = true
      else
        r.end_flg = false
      end
    end
  end

end
