class RedisqResponse
  include ActiveModel::Model
  include ActiveModel::Validations::Callbacks

  attr_accessor *%i(
    is_success victim attackers killID killTime zkb items end_flg
  )

  def self.parse(response)
    new.tap do |r|
      body = JSON.parse(response.body)
      header = response.headers
      r.is_success = response.success?
      if body != ""
        r.items = body['package']
      end
    end
  end

end
