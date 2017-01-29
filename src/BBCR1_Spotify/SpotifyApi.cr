require "json"
require "./SpotifyApi/*"
module Spotify
  class API
    @@token = ""
    ENDPOINT = "https://api.spotify.com/v1"
    JSONREQ = {"Content-Type" => "application/json"} of String => String

    def initialize
    end

    def initialize(token : String)
      @@token = token
    end

    def get(path : String)
      headers = HTTP::Headers{
        "Authorization" => "Bearer #{@@token}",
      }
      response = HTTP::Client.get("#{ENDPOINT}#{path}", headers: headers)
      return response.body
    end

    def getJSON(path : String)
      body = self.get(path)
      return JSON.parse(body)
    end

    def post(path : String, headers : Hash(String, String), postData : Hash(String, String))
      headers_f = HTTP::Headers{
        "Authorization" => "Bearer #{@@token}",
      }
      headers.each do |key, value|
        headers_f[key] = value
      end
      headers = nil

      body = postData.to_json

      response = HTTP::Client.post("#{ENDPOINT}#{path}", headers: headers_f, body: body)
      response.body
    end

    def post(path : String, headers : Hash(String, String), postData : String)
      headers_f = HTTP::Headers{
        "Authorization" => "Bearer #{@@token}",
      }
      headers.each do |key, value|
        headers_f[key] = value
      end
      headers = nil

      response = HTTP::Client.post("#{ENDPOINT}#{path}", headers: headers_f, body: postData)
      response.body
    end

    def postJSON(path : String, headers : Hash(String, String), postData : Hash(String, String))
      body = self.post(path, headers, postData)
      JSON.parse(body)
    end

    def search(artist : String, title : String)
      query = "artist:#{artist} track:#{title}"
      result = self.get("/search?q=#{URI.escape query}&type=track")
      begin
        sr = Spotify::SearchResult.from_json(result)
        if sr.tracks.total >= 1
          return sr.tracks.items[0]
        else
          return nil
        end
      rescue ex : JSON::ParseException
        return nil
      end
    end

    def addTrackToPlaylist(track : Track, userid : Int32, playlistId : String)
      postData = JSON.build do |json|
        json.object do
          json.field "uris" do
            json.array do
              json.string "spotify:track:#{track.id}"
            end
          end
        end
      end
      result = self.post("/users/#{userid}/playlists/#{playlistId}/tracks", JSONREQ, postData)
    end
  end
end
