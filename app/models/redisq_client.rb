class RedisqClient
  @url = nil

  def initialize(url)
    @url = url
  end

  def fetch
    Rails.logger.info("Rediq Access")

    RedisqResponse.parse(get_request_to(@url))
  end

  private

  def build_api_connection
    Faraday.new(url: @url) do |builder|
      builder.request :url_encoded
      builder.adapter Faraday.default_adapter
    end
  end

  def get_request_to(path)
    conn = build_api_connection
    conn.get do |req|
      req.url path
    end
  end

end
