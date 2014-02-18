class YoutubeProxy < BaseProxy

  include ClassLogger

  APP_ID = "Youtube"

  def initialize(options = {})
    super(Settings.youtube_proxy, options)
    @playlist_id = options[:playlist_id]
    @url = @settings.base_url + @playlist_id
    @params = @settings.params.marshal_dump ? @settings.params.marshal_dump : {}
  end

  def get
    self.class.smart_fetch_from_cache(@playlist_id) do
      request_internal(@url, 'videos', @params)
    end
  end

  def request_internal(path, vcr_cassette, params = {})
    #logger.info "Fake = #@fake; Making request to #{url} on behalf of user #{@uid}, student_id = #{student_id}; cache expirat
    response = FakeableProxy.wrap_request(APP_ID + "_" + vcr_cassette, @fake, {:match_requests_on => [:method, :path]}) {
      Faraday::Connection.new(
        :url => @url,
        :params => params,
        :request => {
          :timeout => Settings.application.outgoing_http_timeout
        }
      ).get
    }
    if response.status >= 400
      raise Calcentral::ProxyError.new("Connection failed: #{response.status} #{response.body}")
    end

    logger.debug "Remote server status #{response.status}, Body = #{response.body}"
    {
      :body => response.body,
      :status_code => response.status
    }
  end

end
