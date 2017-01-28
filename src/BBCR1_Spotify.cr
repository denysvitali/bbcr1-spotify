require "./BBCR1_Spotify/*"

require "yaml"
require "http/client"
require "http/server"
require "base64"
require "json"
require "spotify"

class QueryParams
  @@params = {} of String => String

  def self.new(input : Hash(String, String))
    @@params = input
    return self
  end

  def self.to_s
    i = 0
    str = String.build do |str|
      @@params.each do |key, value|
        i += 1
        str << URI.escape(key)
        str << "="
        str << URI.escape(value)
        if i != @@params.size
          str << "&"
        end
      end
    end
  end
end

class SpotifyAPI
  @@token = ""
  ENDPOINT = "https://api.spotify.com/v1"

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
    return response.body
  end

  def post(path : String, headers : Hash(String, String), postData : Hash(String, String))
    body = self.post(path, headers, postData)
    return JSON.parse(body)
  end
end

module BBCR1_Spotify
  JSON_ENDPOINT         = "http://polling.bbc.co.uk/radio/realtime/bbc_radio_one.json"
  SPOTIFY_API_EP        = "https://accounts.spotify.com"
  CREDENTIALS_FILE      = "credentials.yml"
  DEFAULT_PLAYLIST_NAME = "BBCR1 Songs"

  @@client_id = ""
  @@client_secret = ""
  @@token = ""
  @@sApi = SpotifyAPI.new
  @@server = nil
  @@playlistId = ""
  @@myId = -1

  def self.run
    if !File.file? CREDENTIALS_FILE
      puts "ERROR: Credentials file (#{CREDENTIALS_FILE}) is missing!"
      exit
    end

    credentials = {} of YAML::Any => YAML::Any

    begin
      credentials = YAML.parse File.read(CREDENTIALS_FILE)
    rescue ex : YAML::ParseException
      puts "ERROR: Credentials file (#{CREDENTIALS_FILE}) is not a valid YAML file"
      exit
    end

    begin
      if credentials["client_id"] == "" || credentials["client_secret"] == ""
        puts "ERROR: Credentials cannot be empty. Check your credentials file #{CREDENTIALS_FILE}"
        exit
      end
    rescue ex : KeyError
      puts "ERROR: client_id or client_secret is missing from credentials file (#{CREDENTIALS_FILE})"
      exit
    end

    @@client_id = credentials["client_id"].to_s
    @@client_secret = credentials["client_secret"].to_s

    begin
      if credentials["token"]["access_token"] && credentials["token"]["refresh_token"]
        puts "Checking Token"
        self.checkToken(
          credentials["token"]["access_token"].to_s,
          credentials["token"]["refresh_token"].to_s
        )
      end
    rescue ex : KeyError
      puts ex
    end

    begin
      if credentials["playlist"] != ""
        @@playlistId = credentials["playlist"].to_s
      end
    rescue ex : KeyError
      if @@token != ""
        self.createPlaylist
      end
    end

    if @@token == ""
      self.authorize
      exit
    end

    puts "We have a token, ready!"
    self.theLoop
  end

  def self.theLoop
    puts "****"
    if @@sApi
      # puts @@sApi.get("/me/playlists")
    end
  end

  class TokenResponse
    JSON.mapping(
      access_token: String,
      token_type: String,
      expires_in: Int32,
      refresh_token: String | Nil,
      scope: String
    )
  end

  class TokenError
    JSON.mapping(
      error: String,
      error_description: String | Nil
    )
  end

  class AlbumResponse
    JSON.mapping(
      collaborative: Bool,
      description: String | Nil,
      external_urls: Hash(String, String),
      followers: Hash(String, JSON::Any),
      name: String,
      public: Bool,
      tracks: Hash(String, JSON::Any),
      type: String,
      uri: String
    )
  end

  def self.startServer(server : Nil)
  end

  def self.startServer(server : HTTP::Server)
    server.listen
  end

  def self.stopServer(server : Nil)
  end

  def self.stopServer(server : HTTP::Server)
    server.close
  end

  def self.authorize
    str = QueryParams.new({
      "client_id"     => @@client_id,
      "response_type" => "code",
      "redirect_uri"  => "http://localhost:5000/",
      "scope"         => "playlist-modify-public playlist-modify-private playlist-read-private user-library-read",
    }).to_s

    uri = URI.parse("#{SPOTIFY_API_EP}/authorize")
    uri.query = str

    puts "Please visit #{uri} to continue"

    @@server = HTTP::Server.new(5000) do |ctx|
      if ctx.request.path == "/"
        params = ctx.request.query_params
        if params.has_key? "code"
          self.getToken(params["code"])
        end
      end
    end
    startServer @@server
  end

  def self.refreshToken(rtoken)
    self.getToken(rtoken, "refresh")
  end

  def self.getToken(code, gtype = "auth")
    puts "GetToken #{gtype} #{@@client_id}:#{@@client_secret}"

    if gtype == "auth"
      body = {
        "grant_type"   => "authorization_code",
        "code"         => code,
        "redirect_uri" => "http://localhost:5000/",
      }
    else
      # Refresh Token
      body = {
        "grant_type"    => "refresh_token",
        "refresh_token" => code,
      }
    end

    auth = Base64.strict_encode("#{@@client_id}:#{@@client_secret}")
    headers = HTTP::Headers{
      "Authorization" => "Basic #{auth}",
    }
    response = HTTP::Client.post_form("#{SPOTIFY_API_EP}/api/token", body, headers: headers)

    token = nil
    error = nil

    begin
      token = TokenResponse.from_json(response.body)
    rescue ex : JSON::ParseException
      error = TokenError.from_json(response.body)
    end
    if error
      puts "ERROR: Unable to get token!"
      exit
    end
    if token
      self.saveToken token
    end
  end

  def self.saveToken(token : TokenResponse)
    credentials = YAML.parse File.read(CREDENTIALS_FILE)
    credentials = credentials.as_h
    credentials["token"] = {
      "access_token"  => token.access_token,
      "refresh_token" => token.refresh_token,
    } of YAML::Type => YAML::Type
    credentials = credentials.to_yaml
    File.write(CREDENTIALS_FILE, credentials)
    @@token = token
    self.stopServer @@server
  end

  def self.checkToken(token : String, refresh_token : String)
    sApi = SpotifyAPI.new(token)
    me = sApi.getJSON("/me")
    begin
      if me["error"]?
        # AT expired, refreshing
        if refresh_token != ""
          puts "Refreshing token"
          self.refreshToken refresh_token
        else
          puts "Token + Refresh Token expired! Please, reauthenticate"
          self.authorize
        end
      end
    rescue ex
    end
    puts me
    @@myId = me["id"].to_s.to_i { -1 }
    @@token = token
    @@sApi = sApi
  end

  def self.createPlaylist
    result = @@sApi.post("/users/#{@@myId}/playlists",
      {"Content-Type" => "application/json"},
      {
        "name"   => DEFAULT_PLAYLIST_NAME,
        "public" => "true",
      })
    begin
      result = AlbumResponse.from_json(result)
      puts result
    rescue ex : JSON::ParseException
      puts "ERROR: Unable to create playlist: #{ex}"
    end
  end

  self.run
end
