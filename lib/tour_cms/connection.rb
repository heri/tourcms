module TourCMS
  class Connection
    def initialize(marketp_id, private_key, result_type = "raw")
      Integer(marketp_id) rescue raise ArgumentError, "Marketplace ID must be an Integer"
      @marketp_id = marketp_id
      @private_key = private_key
      @result_type = result_type
      @base_url = "https://api.tourcms.com"
    end
    
    def api_rate_limit_status(channel = 0)
      request("/api/rate_limit_status.xml", channel)
    end
    
    def list_channels
      request("/p/channels/list.xml")
    end
    
    def show_channel(channel)
      request("/c/channel/show.xml", channel)
    end
    
    def search_tours(params = {}, channel = 0)
      if channel == 0
        request("/p/tours/search.xml", 0, params)
      else
        request("/c/tours/search.xml", channel, params)
      end
    end
    
    def search_hotels_range(params = {}, tour = "", channel = 0)
      if channel == 0
        request("/p/hotels/search_range.xml", 0, params.merge({"single_tour_id" => tour}))
      else
        request("/c/hotels/search_range.xml", channel, params.merge({"single_tour_id" => tour}))
      end
    end
    
    def search_hotels_specific(params = {}, tour = "", channel = 0)
      if channel == 0
        request("/p/hotels/search-avail.xml", 0, params.merge({"single_tour_id" => tour}))
      else
        request("/c/hotels/search-avail.xml", channel, params.merge({"single_tour_id" => tour}))
      end
    end
    
    def list_tours(channel = 0)
      if channel == 0
        request("/p/tours/list.xml")
      else
        request("/c/tours/list.xml", channel)
      end
    end
    
    def list_tour_images(channel = 0)
      if channel == 0
        request("/p/tours/images/list.xml")
      else
        request("/c/tours/images/list.xml", channel)
      end
    end
    
    def show_tour(tour, channel)
      request("/c/tour/show.xml", channel, {"id" => tour})
    end
    
    def show_tour_departures(tour, channel)
      request("/c/tour/datesprices/dep/show.xml", channel, {"id" => tour})
    end
    
    def show_tour_freesale(tour, channel)
      request("/c/tour/datesprices/freesale/show.xml", channel, {"id" => tour})
    end
    
    private
    
    def return_result(result)
      if @result_type == "raw"
        result
      else
        XMLObject.new(result)
      end
    end
        
    def construct_params(param_hash)
      if param_hash.empty?
        res = ""
      else
        qs = param_hash.stringify.reject{|k,v| v.nil? || v.empty?}.collect{|k,v|"#{CGI.escape(k)}=#{CGI.escape(v)}"}.join("&")
        qs.empty? ? res = "" : res = "?#{qs}"
      end
      res
    end
    
    def generate_signature(path, verb, channel, outbound_time)
      string_to_sign = "#{channel}/#{@marketp_id}/#{verb}/#{outbound_time}#{path}".strip
      
      dig = OpenSSL::HMAC.digest('sha256', @private_key, string_to_sign)
      b64 = Base64.encode64(dig).chomp
      CGI.escape(b64).gsub("+", "%20")
    end
    
    def request(path, channel = 0, params = {}, verb = "GET")
      url = @base_url + path + construct_params(params)
      req_time = Time.now.utc
      signature = generate_signature(path + construct_params(params), verb, channel, req_time.to_i)
      
      headers = {"Content-type" => "text/xml", "charset" => "utf-8", "Date" => req_time.strftime("%a, %d %b %Y %H:%M:%S GMT"), 
        "Authorization" => "TourCMS #{channel}:#{@marketp_id}:#{signature}" }
            
      @result_type == "raw" ? open(url, headers) : doc = Hash.from_xml(open(url, headers))[:response]
    end
  end
end
