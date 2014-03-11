module CalLink
  class Organization < Proxy

    include SafeJsonParser

    def initialize(options = {})
      super(options)
      @org_id = options[:org_id]
    end

    def self.cache_key(org_id)
      "global/#{self.name}/#{org_id}"
    end

    def get_organization
      self.class.smart_fetch_from_cache({id: @org_id, user_message_on_exception: "Remote server unreachable"}) do
        request_internal
      end
    end

    def request_internal
      url = "#{Settings.cal_link_proxy.base_url}/api/organizations"
      params = build_params
      Rails.logger.info "#{self.class.name}: Fake = #@fake; Making request to #{url}; params = #{params}, cache expiration #{self.class.expires_in}"

      response = FakeableProxy.wrap_request(APP_ID + "_organization", @fake, {:match_requests_on => [:method, :path, self.method(:custom_query_matcher).to_proc, :body]}) {
        Faraday::Connection.new(
          :url => url,
          :params => params,
          :request => {
            :timeout => Settings.application.outgoing_http_timeout
          }
        ).get
      }
      if response.status >= 400
        raise Calcentral::ProxyError.new("Connection failed: #{response.status} #{response.body}; url = #{url}")
      end
      Rails.logger.debug "#{self.class.name}: Remote server status #{response.status}, Body = #{response.body}"
      {
        :body => safe_json(response.body),
        :status_code => response.status
      }
    end

    private

    def custom_query_matcher(uri_1, uri_2)
      a_uri = URI(uri_1.uri).query
      b_uri = URI(uri_2.uri).query
      if !a_uri.blank? && !b_uri.blank?
        a_param_hash = CGI::parse(a_uri)
        b_param_hash = CGI::parse(b_uri)
        a_param_hash["organizationId"] == b_param_hash["organizationId"]
      else
        a_uri == b_uri
      end
    end

    def build_params
      params = super
      params.merge(
        {
          :organizationId => @org_id
        })
    end


  end
end
