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
require 'xmlsimple'
require 'cgi'

class Tvdb
  API_KEY = "A97A9243F8030477"
  def initialize
    @host = 'http://www.thetvdb.com/api'
  end

  def http_get(url)
    puts "escaped uri: " + url
    Net::HTTP.get_response(URI.parse(url)).body.to_s
  end
  
  def find_series_id_by_name(series_name)
    series_name = URI.escape(series_name).gsub('&', '%26').gsub(':', '%3A')
    puts "#{@host}/GetSeries.php?seriesname=#{series_name}"
    response = XmlSimple.xml_in(http_get("#{@host}/GetSeries.php?seriesname=#{series_name}"), { 'ForceArray' => false })
    case response["Series"]
    when Array
      response["Series"][0]["seriesid"]
    when Hash
      response["Series"]["seriesid"]
    end
  end

  def search(series_name)
    series_name = URI.escape(series_name).gsub('&', '%26').gsub(':', '%3A')
    response = XmlSimple.xml_in(http_get("#{@host}/GetSeries.php?seriesname=#{series_name}"), { 'ForceArray' => false })
    case response["Series"]
    when Array
      Series.new(response["Series"].first)
    when Hash
      Series.new(response["Series"])
    end
  end
  
  def find_series_by_id(series_id)
    puts "#{@host}/#{API_KEY}/series/#{series_id}/en.xml"
    response = XmlSimple.xml_in(http_get("#{@host}/#{API_KEY}/series/#{series_id}/en.xml"), { 'ForceArray' => false })
    Series.new(response["Series"])
  end

  def get_episodes(series_id)
    episodes = []
    response = XmlSimple.xml_in(http_get("#{@host}/GetEpisodes.php?seriesid=#{series_id}"), { 'ForceArray' => false })
    response["Item"].delete_at 0
    case response["Item"].class.name
    when "Array"
      response["Item"].each { |item| episodes << Episode.new(episode_updates(item["id"])) if item["EpisodeName"]}
    when "Hash"
      episodes << Episode.new(response["Item"])
    end
    
    episodes
    
  end

  # def episode_updates(item_id)
  #   response = XmlSimple.xml_in(http_get("#{@host}/EpisodeUpdates.php?idlist=#{item_id}"), { 'ForceArray' => false })
  #   response["Item"][1]
  # end
  
  def get_episode(series_id, season_num, episode_num)
    response = XmlSimple.xml_in(http_get("#{@host}/#{API_KEY}/series/#{series_id}/default/#{season_num}/#{episode_num}/en.xml"), { 'ForceArray' => false })
    response["Episode"]

  end


  def get_banners(series_id)
    banners = []
    response = XmlSimple.xml_in(http_get("#{@host}/#{API_KEY}/series/#{series_id}/banners.xml"), { 'ForceArray' => false })
    case response["Banner"].class.name
    when "Array"
      response["Banner"].each { |item| banners << Banner.new(item) if item["BannerType"]}
    when "Hash"
      banners << Banner.new(response["Banner"])
    end
    
    banners 
    
  end

  class Series
    attr_accessor :id, :name, :overview, :seasons, :banners, :first_aired, :genres, :network, :rating, :runtime
    

    def initialize(details)
      @client = Tvdb.new
      @seasons = {} 
      @genres = []
      @id = details["id"]
      @name = details["SeriesName"]
      @overview = details["Overview"] unless details["Overview"].class == Hash
      @first_aired = Date.parse(details["FirstAired"]) if details["FirstAired"].size > 0 
      @genres = details["Genre"][1..-1].split("|") if details["Genre"].size > 0 
      @network = details["Network"]
      @runtime = details["Runtime"] if details["Runtime"].size > 0

      if details["Rating"].size > 0
        @rating = details["Rating"].to_f
      else
        @rating = 0
      end
      
      @banners = {}
      @banners["graphical"] = []
      @banners["poster"] = []
      @banners["season"] = {}
      
    end

    def retrieve_all_episodes
      @client.get_episodes(@id)
    end
    
    def retrieve_banners
      banners = @client.get_banners(@id)

      banners.each do |banner|
        case banner.banner_type
        when /series/i
          @banners["graphical"] << "http://thetvdb.com/banners/" + banner.path if banner.language == 'en' && banner.banner_type2 =~ /graphical/i
        when /poster/i
          @banners["poster"] << "http://thetvdb.com/banners/" + banner.path if banner.language == 'en'
        when /season/i
          @banners["season"][banner.season] = "http://thetvdb.com/banners/" + banner.path if banner.language == 'en' &&  banner.banner_type2 =~ /season$/i
        end
      end

    end

    def fill_all_meta
      retrieve_all_episodes.each do |episode|
        if @seasons.key? episode.season_number
          @seasons[episode.season_number][episode.number] = episode
        else
          @seasons[episode.season_number] = {episode.number => episode}
        end
      end
    end
    
    def episode(season_num, episode_num)
      begin
        Episode.new(@client.get_episode(@id, season_num, episode_num))        
      rescue 
        nil
      end
    end

  end

  class Episode
    attr_accessor :id, :season_number, :number, :name, :overview, :air_date, :thumb

    def initialize(details)
      @id = details["id"]
      @season_number = details["SeasonNumber"].to_s
      @number = details["EpisodeNumber"].to_s
      @name = details["EpisodeName"].to_s
      @overview = details["Overview"].to_s
      @air_date = details["FirstAired"].to_s
      @thumb = "http://thetvdb.com/banners/" + details["filename"] if details["filename"].to_s != ""
    end
  end

  class Banner
    attr_accessor :type, :banner_type, :banner_type2, :season, :path, :language

    def initialize(details)
      @type = details["Type"]
      @banner_type = details["BannerType"]
      @banner_type2 = details["BannerType2"]
      @season = details["Season"]
      @path = details["BannerPath"]
      @language = details["Language"]
    end
  end
    
end
