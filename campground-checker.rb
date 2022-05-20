#!/usr/bin/ruby -w
require 'open-uri'
require 'pry'
require 'optparse'
require 'optparse/time'
require 'json'
require 'net/http'
require 'rest-client'
require './clients/recreation_client'


class Scraper
	

	def main
		
		#get user input with options for park id, start date, and end date, campsite type, campsite id
		
		options = {
		:parks => [], 
		:campsite_ids => []
		}
		OptionParser.new do |opt|
		opt.on('--start_date STARTDATE', Time) { |o| options[:start_date] = o.strftime("%F")}
		opt.on('--end_date STARTDATE', Time) { |o| options[:end_date] = o.strftime("%F")}
		opt.on('-p', '--parks PARKS1,PARKS2,...', Array, "Parks")	do |f|
				options[:parks] += f 
			end
		opt.on('--campsite_type TYPE') { |o| options[:campsite_type] = o }
		opt.on('-p', '--campsite_ids IDS1,IDS2,...', Array, "Ids")	do |f|
				options[:campsite_ids] += f 
			end
		opt.on('--nights NIGHTS') { |o| options[:nights] = o }
		end.parse!
		
		puts options
		
		
		

		json_output=false
	
		info_by_park_id = {}
		for park_id in options[:parks]
			info_by_park_id[park_id] = single_park(
            		park_id,
           		 options[:start_date],
            		options[:end_date], 
			options[:campsite_type], 
			options[:campsite_ids], 
			options[:nights]
			
        	)
		end
	
		if json_output
			output, has_availabilities = gen_json_output(info_by_park_id)
		else 
			output, has_availabilities = generate_human_output(
            		info_by_park_id,
            		options[:start_date],
            		options[:end_date]
        	)
		end
		print output
		return has_availabilities

		
	end
	

	def get_park_info(
    park_id, start_date, end_date, campsite_type="", campsite_ids=[]
)
		#get the first of each month in the chosen range
		start_of_month = Date.new(Date.parse(start_date).year, Date.parse(start_date).mon, 1)
		
		rrule = RRule::Rule.new('FREQ=MONTHLY',dtstart: DateTime.parse(start_of_month.to_s))
		 
		
		months = rrule.between(DateTime.parse(start_of_month.to_s), DateTime.parse(end_date)).to_a
		
		#get data from each month
		api_data = []
		for mon_date in months do
			api_data.push(RecClient.get_availability(park_id, month_date))
		end
		
		#collapse data to get useable data
		#option to filter by campsite_type 
		data = {}
		
		for mon_data in api_data
			
			
			for campsite_id, campsite_data in mon_data["campsites"]
				available = []
				
				data.store(campsite_id,[])
				for date, availability_value in campsite_data["availabilities"]
				
					if availability_value != "Available" then
						next
					
					elsif (campsite_type and campsite_type != campsite_data["campsite_type"] 
					) then
						next
					
					elsif (campsite_ids ==true) && (campsite_ids.include?(campsite_data["campsite_id"].to_i) == false) then
                 
						next
					end
					available.append(date)
				end
				if available
					data[campsite_id]= available
				end
				
			end
		end
		
		
			
		return data
	end
				
	def single_park(park_id, start_date, end_date, campsite_type, campsite_ids=[], nights=nil
	)
		park_info = get_park_info(park_id, start_date, end_date, campsite_type, campsite_ids
		)
		
		park_name = RecClient.get_park_name(park_id)

		current, max, availabilities_filtered = 
		get_availability(park_info, start_date, end_date, nights=nights
		 )
		 
		return current, max, availabilities_filtered, park_name
		
		
	end
	
	
	def get_availability(park_info, start_date, end_date, nights=nil
	)
		nights = nights.to_i
		num_available = 0
		max = park_info.length
		start = DateTime.parse(start_date)
		end_d = DateTime.parse(end_date)
		
		num_days = (end_d - start).to_i
		
		dates = []
		
		for i in 1..(num_days) do 
			
			difference = end_d - i
			s_date = DateTime.parse(difference.to_s).strftime( "%Y-%m-%dT00:00:00Z")
			 dates.append(s_date)
		end
		
		if (nights.between?(1, num_days) == false) 
			nights = num_days
			print ("Setting number of nights to #{nights}.")
		end
		
		
		
		available_dates_by_campsite_id = Hash.new{|h, k| h[k] = []}
		for site, availabilities in park_info
			#list of dates that are within range of stay
			desired_dates = []
			for date in availabilities
				
				if (dates.include?(date) == false)
					next
				
				end
					desired_dates.append(date)
				
			end
			unless desired_dates
				next
			end	
			
			
			appropriate_consecutive_ranges = consecutive_nights(
            desired_dates, nights
			)
			
			
			if  appropriate_consecutive_ranges != []
				num_available += 1
				#print ("Available site #{num_available} : #{site}")
			end
			
			for r in appropriate_consecutive_ranges
				start, end_r = r
				
				
				available_dates_by_campsite_id[site.to_i].append("start": start, "end": end_r)
				
				
			end
			
			
		end

		return num_available, max, available_dates_by_campsite_id

	end

	def consecutive_nights(available, nights)
		'''
		Returns list of dates with enough consecutive nights.
		'''
				
		start_d = DateTime.new(1,1,1)
			
		ordinal_dates = []
		for dstr in available 
				
				o_time = (DateTime.parse(dstr) - start_d - 1).to_i
				
				ordinal_dates.append(o_time)
				
			
		end
		 
		
		enum = ordinal_dates.slice_when { |x,y| y > x+1 }
		consective_ranges = enum.to_a
		
		long_enough_consecutive_ranges = []

		for r in consective_ranges
       		#skip ranges less than length of stay
			if r.length < nights
				next
			end
			for start_index in 0..r.length - nights
					
				start_nice = DateTime.parse(start_d.next_day(r[start_index]+1).to_s).strftime( "%Y-%m-%d")
				
				end_nice = DateTime.parse(start_d.next_day(r[start_index + nights - 1] + 2).to_s).strftime( "%Y-%m-%d")
				
				
				long_enough_consecutive_ranges.append([start_nice, end_nice])
				
			end
			
			
		end
		
		
		return long_enough_consecutive_ranges

	end

	def gen_human_output(
    info_by_park_id, start_date, end_date, gen_campsite_info=false
)
	out = []
    	has_availabilities = false
	
		for park_id, info in info_by_park_id
			current, maximum, available_dates_by_site_id, park_name = info
			if current > 0
				print ("SUCCESS ")
				has_availabilities = true
		
			else
				print ("FAILURE ")
			end
			out.append(
            "#{park_name} (#{park_id}): #{current} site(s) open out of #{maximum} site(s)"  
            
            )
			#displays campsite id and available dates
			if gen_campsite_info and available_dates_by_site_id
				for site_id, dates in available_dates_by_site_id
                out.append(
                    "  * Site #{site_id} is open for booking on the dates:"
                )
				
					for date in dates
					start=date["start"]
					end_s=date["end"]
                    out.append(
                        "    * #{start} -> #{end_s}"
                            
                        
                    )
					end
				end
			end
		
	
		end
		if has_availabilities
			start=DateTime.parse(start_date.to_s).strftime( "%Y-%m-%d")
			end_p=DateTime.parse(end_date.to_s).strftime( "%Y-%m-%d")
			out.insert(
            0,
            "there are campsites open from #{start} to #{end_p}!!!"
            
			)
		else
        out.insert(0, "No campsites are available")
		end
	
		return (out).join("\n"), has_availabilities

	end

	def gen_json_output(info_by_park_id)
		availabilities_by_park_id = {}
		has_availabilities = false
		for park_id, info in info_by_park_id
        current, _, available_dates_by_site_id, _ = info
			if current
				has_availabilities = true
				availabilities_by_park_id[park_id] = available_dates_by_site_id
			end
		end
		
		return json.dump(availabilities_by_park_id), has_availabilities
	end
	
	
end

	
scrape = Scraper.new
scrape.main


