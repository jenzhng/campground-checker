#!/usr/bin/ruby -w



class RecreationClient
	
	BASE_URL = "https://www.recreation.gov"
	AVAILABILITY_ENDPOINT = (
		BASE_URL + "/api/camps/availability/campground/%d/month"
	)
	MAIN_PAGE_ENDPOINT = BASE_URL + "/api/camps/campgrounds/%d"
	    
	
	class << self
		def get_availability(park_id, month_date)
			
			params = {"start_date": DateTime.parse(month_date.to_s).strftime("%Y-%m-%dT00:00:00.000Z")}
			
			url = Kernel::format(AVAILABILITY_ENDPOINT, park_id)
			
			
			resp = _send_requests(url, params)
			
			data = JSON.parse(resp.body)
			return data
			
		
		end
	end
	
	
	class << self 
		def get_park_name(park_id)
			url = Kernel::format(MAIN_PAGE_ENDPOINT, park_id)
			resp = _send_requests(url, params=nil)
			data = JSON.parse(resp.body)
			return data["campground"]["facility_name"]
		end
	end
	
	class << self
		def _send_requests(url, params)
			
			 return RestClient::Request.execute(method: :get, url: url,
                            timeout: 10, headers: {params: params})
			case response.code
				when 200
					p "It worked !"
					response
				when 423
					raise SomeCustomExceptionIfYouWant
				else
					response.return!(&block)
			end
		end
	end
end	

	

