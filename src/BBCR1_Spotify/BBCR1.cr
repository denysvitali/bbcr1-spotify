require "json"
require "./BBCR1/*"

module BBCR1
  JSON_ENDPOINT = "http://polling.bbc.co.uk/radio/realtime/bbc_radio_one.json"

  class CurrentSong
    def self.get
      headers = HTTP::Headers{
        "User-Agent" => "bbcr1-spotify (https://github.com/denysvitali/bbcr1-spotify)",
      }
      response = HTTP::Client.get("#{JSON_ENDPOINT}", headers: headers)
      begin
        return NowPlaying.from_json(response.body)
      rescue ex : JSON::ParseException
        puts "Unable to parse BBCR1 Now Playing: #{ex}"
      end
    end
  end
end
