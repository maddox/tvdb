####### The Tvdb API
### http://thetvdb.com

# tvdb = Tvdb.new
# results = tvdb.search("Scrubs")
# 
# series = results.first
# series.banners
# 
# series.banners.each { |e| puts e.inspect }
# series.episodes.each { |e| puts e.inspect }



require 'rubygems'
require 'net/http'
require 'cgi'
require 'xmlsimple'

class Tvdb
  
  def initialize
    @host = 'http://thetvdb.com/interfaces'
  end

  def http_get(url)
    Net::HTTP.get_response(URI.parse(URI.encode(url))).body.to_s
  end


  def search(series_name)
    series = []
    response = XmlSimple.xml_in(http_get("#{@host}/GetSeries.php?seriesname=#{series_name}"), { 'ForceArray' => false })

    case response["Item"].class.name
    when "Array"
      response["Item"].each { |item| series << Series.new(item)}
    when "Hash"
      series << Series.new(response["Item"])
    end

    series 
  end

  def get_episodes(series_id)
    episodes = []
    response = XmlSimple.xml_in(http_get("#{@host}/GetEpisodes.php?seriesid=#{series_id}"), { 'ForceArray' => false })

    case response["Item"].class.name
    when "Array"
      response["Item"].each { |item| episodes << Episode.new(item) if item["EpisodeName"]}
    when "Hash"
      episodes << Series.new(response["Item"])
    end
    
    episodes 
    
  end

  def get_banners(series_id)
    banners = []
    response = XmlSimple.xml_in(http_get("#{@host}/GetBanners.php?seriesid=#{series_id}"), { 'ForceArray' => false })

    case response["Item"].class.name
    when "Array"
      response["Item"].each { |item| banners << Banner.new(item) if item["BannerType"]}
    when "Hash"
      banners << Banner.new(response["Item"])
    end
    
    banners 
    
  end



  def get_nzb(id)
    response = Net::HTTP.post_form(URI.parse("#{@host}#{@dnzb}"),{:username => @username, :password => @password, :reportid => id})

    case response["x-dnzb-rcode"].to_i
    when 200
      puts "NZB downloaded OK"
      response.body
    when 450
      puts "ERROR 450: 5 nzbs per minute please."
      false
    else 
      puts "ERROR #{response["x-dnzb-rcode"]}: #{response["x-dnzb-rtext"]}"
      false
    end
  
  end

  class Series
    attr_accessor :id, :status, :runtime, :airs_time, :airs_day_of_week, :genre, :name, :overview, :network
    
    @seasons = {}
    @episodes = {}

    def initialize(details)
      @id = details["id"]
      @status = details["Status"]
      @runtime = details["Runtime"]
      @airs_time = details["Airs_Time"]
      @airs_day_of_week = details["Airs_DayOfWeek"]
      @genre = details["Genre"]
      @name = details["SeriesName"]
      @overview = details["Overview"]
      @network = details["Network"] 

      @client = Tvdb.new
    end
    
    def episodes
      @client.get_episodes(@id)
    end
    
    def banners
      @client.get_banners(@id)
    end
  end

  class Episode
    attr_accessor :id, :season_number, :number, :name

    def initialize(details)
      @id = details["id"]
      @season_number = details["SeasonNumber"]
      @number = details["EpisodeNumber"]
      @name = details["EpisodeName"]
    end
  end

  class Banner
    attr_accessor :type, :banner_type, :season, :path

    def initialize(details)
      @type = details["Type"]
      @banner_type = details["BannerType"]
      @season = details["Season"]
      @path = details["BannerPath"]
    end
  end
    
end

