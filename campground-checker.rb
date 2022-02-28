#!/usr/bin/ruby -w
require 'nokogiri'
require 'open-uri'
require 'pry'
require 'optparse'
require 'optparse/time'
require 'json'
require 'net/http'
require 'rest-client'


BASE_URL = "https://www.recreation.gov"
#AVAILABILITY_ENDPOINT = "/api/camps/availability/campground/"
MAIN_PAGE_ENDPOINT = "/api/camps/campgrounds/"
TEST_URL = "https://www.recreation.gov/api/camps/availability/campground/"


class Scraper
	

	def get_info

		options = {}
		OptionParser.new do |opt|
		opt.on('--start_date STARTDATE', Time) { |o| options[:start_date] = o.strftime("%F")}
		opt.on('--parks PARKS') { |o| options[:parks] = o }
		end.parse!
		
		puts options
		
		
		temp_url = TEST_URL << options[:parks] <<
		"/month?start_date=" << options[:start_date] << "T00%3A00%3A00.000Z"
		html = URI.parse(temp_url)
		response = Net::HTTP.get_response(html)
		response.body
		
		camps = JSON.parse(response.body)
		

		get_name_of_park(options[:parks])

		
		
		
		binding.pry
		
	end
	
	def get_name_of_park(park_id)
			url = BASE_URL << MAIN_PAGE_ENDPOINT << park_id
			page = URI.parse(url)
			resp = Net::HTTP.get_response(page)
			park_name = JSON.parse(resp.body)

		puts park_name["campground"]["facility_name"]
	end

	
end

	
scrape = Scraper.new
scrape.get_info


