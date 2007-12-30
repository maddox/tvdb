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

class Tvdb
  
  def initialize
    @host = 'http://thetvdb.com/interfaces'
  end

  def http_get(url)
    puts url
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
    response["Item"].delete_at 0
    case response["Item"].class.name
    when "Array"
      response["Item"].each { |item| episodes << Episode.new(episode_updates(item["id"])) if item["EpisodeName"]}
    when "Hash"
      episodes << Episode.new(response["Item"])
    end
    
    episodes
    
  end

  def episode_updates(item_id)
    response = XmlSimple.xml_in(http_get("#{@host}/EpisodeUpdates.php?idlist=#{item_id}"), { 'ForceArray' => false })
    response["Item"][1]
  end
  
  def get_episode(series_id, season_num, episode_num)
    response = XmlSimple.xml_in(http_get("#{@host}/GetEpisodes.php?seriesid=#{series_id}&season=#{season_num}&episode=#{episode_num}"), { 'ForceArray' => false })
    response["Item"][1]

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

  class Series
    attr_accessor :id, :status, :runtime, :airs_time, :airs_day_of_week, :genre, :name, :overview, :network, :seasons
    

    def initialize(details)
      @seasons = {}
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

    def retrieve_all_episodes
      @client.get_episodes(@id)
    end
    
    def retrieve_banners
      @client.get_banners(@id)
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
      
      Episode.new(@client.episode_updates(@client.get_episode(@id, season_num, episode_num)["id"]))
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
      puts details["filename"].inspect
      @thumb = "http://thetvdb.com/banners/" + details["filename"] if details["filename"].to_s != ""
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
