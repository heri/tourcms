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
      return_result(request("/api/rate_limit_status.xml", channel))
    end
    
    def list_channels
      return_result(request("/p/channels/list.xml"))
    end
    
    def show_channel(channel)
      return_result(request("/c/channel/show.xml", channel))
    end
    
    def search_tours(params = {}, channel = 0)
      if channel == 0
        return_result(request("/p/tours/search.xml", 0, params))
      else
        return_result(request("/c/tours/search.xml", channel, params))
      end
    end
    
    def search_hotels_range(params = {}, tour = "", channel = 0)
      if channel == 0
        return_result(request("/p/hotels/search_range.xml", 0, params.merge({"single_tour_id" => tour})))
      else
        return_result(request("/c/hotels/search_range.xml", channel, params.merge({"single_tour_id" => tour})))
      end
    end
    
    def search_hotels_specific(params = {}, tour = "", channel = 0)
      if channel == 0
        return_result(request("/p/hotels/search-avail.xml", 0, params.merge({"single_tour_id" => tour})))
      else
        return_result(request("/c/hotels/search-avail.xml", channel, params.merge({"single_tour_id" => tour})))
      end
    end
    
    def list_tours(channel = 0)
      if channel == 0
        return_result(request("/p/tours/list.xml"))
      else
        return_result(request("/c/tours/list.xml", channel))
      end
    end
    
    def list_tour_images(channel = 0)
      if channel == 0
        return_result(request("/p/tours/images/list.xml"))
      else
        return_result(request("/c/tours/images/list.xml", channel))
      end
    end
    
    def show_tour(tour, channel)
      return_result(request("/c/tour/show", channel, {"id" => tour}))
    end
    
    def show_tour_departures(tour, channel)
      return_result(request("/c/tour/datesprices/dep/show.xml", channel, {"id" => tour}))
    end
    
    def show_tour_freesale(tour, channel)
      return_result(request("/c/tour/datesprices/freesale/show.xml", channel, {"id" => tour}))
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
        qs = param_hash.stringify_keys.reject{|k,v| v.nil? || v.empty?}.collect{|k,v|"#{CGI.escape(k)}=#{CGI.escape(v)}"}.join("&")
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
      
      begin
        response = open(url, headers).read
      rescue Exception => e
        puts "Caught exception opening #{url}"
        puts e.message
        puts e.backtrace.inspect
      rescue OpenURI::HTTPError => http_e
        puts "Received HTTP Error opening #{url}"
        puts http_e.io.status[0].to_s
      end
    end
  end
end
