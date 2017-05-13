class ZkillClient
  ZKILL_API_BASE_URL = 'https://zkillboard.com/api'.freeze
  KILL_URL = '/killID/'

  def fetch_loss(kill_id)
    path = kill_mail_url(kill_id)
    Rails.logger.info("ZkillClient Access to #{path}")

    ZkillResponse.parse(get_request_to(path))
  end

  def get_kill_id_from_url(url)
    url.split(/\//).last
  end

  def general_fetch(param, current_page: 1)
    path = ZKILL_API_BASE_URL + param.to_s

    ZkillResponse.parse_j(get_request_to(path), current_page: current_page)
  end

  def fetch_loss_by_day_and_region(stime, etime, sid, page)
    path = ZKILL_API_BASE_URL +
      "/losses/solarSystemID/#{sid}/startTime/#{stime}/endTime/#{etime}/page/#{page}/no-items/"
    Rails.logger.info("Start ZkillClient Access to #{path}")

    r = ZkillResponse.parse_j(get_request_to(path), current_page: page)

    Rails.logger.info("End ZkillClient Access to #{path}")
    r
  end

  private

  def build_api_connection
    Faraday.new(url: ZKILL_API_BASE_URL) do |builder|
      builder.request :url_encoded
      builder.adapter Faraday.default_adapter
    end
  end

  def get_request_to(path)
    conn = build_api_connection
    conn.get do |req|
      req.url path
      req.headers['Accept-Encoding'] = 'gzip'
      req.headers['User-Agent'] = Settings.applications.zkill_user_agent
    end
  end

  def kill_mail_url(kill_id)
    ZKILL_API_BASE_URL + KILL_URL + kill_id.to_s + '/'
  end

end
