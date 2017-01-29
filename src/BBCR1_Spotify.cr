require "./BBCR1_Spotify/*"

require "yaml"
require "http/client"
require "http/server"
require "base64"
require "json"

module BBCR1_Spotify
  SPOTIFY_API_EP        = "https://accounts.spotify.com"
  CREDENTIALS_FILE      = "credentials.yml"
  DEFAULT_PLAYLIST_NAME = "BBCR1 Songs"

  @@client_id = ""
  @@client_secret = ""
  @@token = ""
  @@sApi = Spotify::API.new
  @@server = nil
  @@playlistId = ""
  @@myId = -1
  @@lastTrack = ""

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
        playlist = self.createPlaylist
        if playlist != ""
          savePlaylist(playlist)
        else
          puts "ERROR: Unable to create playlist"
          exit
        end
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
    song = BBCR1::CurrentSong.get
    self.checkAndRefresh
    if song
      if song.realtime
        puts song.realtime.title
        puts song.realtime.artist

        title = song.realtime.title

        artist = song.realtime.artist
        artist_clean = artist.gsub(/ & /, ",")

        if @@lastTrack != "#{artist} - #{title}"
          @@lastTrack = "#{artist} - #{title}"
          if @@sApi
            puts @@playlistId

            track = @@sApi.search(artist_clean, title)
            if track
              @@sApi.addTrackToPlaylist(track, @@myId, @@playlistId)
              puts "Adding #{track.name} by #{track.artists[0].name}"
            else
              title_clean = title.match(/[^()]+/)
              if title_clean
                track = @@sApi.search(artist_clean, title_clean[0])
                if track
                  @@sApi.addTrackToPlaylist(track, @@myId, @@playlistId)
                  puts "Adding #{track.name} by #{track.artists[0].name}"
                else
                  puts "Unable to find #{artist} - #{title}"
                end
              else
                puts "Unable to clean title"
              end
            end
          end
        end
      end
    end
    sleep 30
    self.theLoop
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

  def self.refreshToken(token : Array(YAML::Type))
    puts typeof(token)
    #self.refreshToken(token["refresh_token"])
  end

  def self.refreshToken(rtoken : String)
    self.getToken(rtoken, "refresh")
  end

  def self.refreshToken(token)
    puts typeof(token)
    puts token
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
      token = Spotify::TokenResponse.from_json(response.body)
    rescue ex : JSON::ParseException
      error = Spotify::TokenError.from_json(response.body)
    end
    if error
      puts "ERROR: Unable to get token!"
      exit
    end
    if token
      self.saveToken token
    end
  end

  def self.saveToken(token : Spotify::TokenResponse)
    credentials = self.getCred
    if token.refresh_token == nil
     token.refresh_token = self.getRefreshToken(credentials["token"])
    end
    credentials["token"] = {
      "access_token"  => token.access_token,
      "refresh_token" => token.refresh_token,
    } of YAML::Type => YAML::Type
    self.writeCred(credentials)
    @@token = token.access_token
    self.stopServer @@server
  end

  def self.getRefreshToken(token : Hash(YAML::Type, YAML::Type))
    token["refresh_token"].to_s
  end

  def self.getRefreshToken(token)
    ""
  end

  def self.checkToken(token : String, refresh_token : String)
    sApi = Spotify::API.new(token)
    me = sApi.getJSON("/me")
    begin
      if me["error"]?
        # AT expired, refreshing
        if refresh_token != ""
          puts "Refreshing token"
          self.refreshToken refresh_token
          self.checkToken(@@token, "")
          return
        else
          puts "Token + Refresh Token expired! Please, reauthenticate"
          self.authorize
        end
      end
    rescue ex
    end
    @@myId = me["id"].to_s.to_i { -1 }
    @@token = token
    @@sApi = sApi
  end

  def self.checkAndRefresh
    if @@sApi
      result = @@sApi.get("/me")
      if result
        begin
          if result["id"] != nil
            # No need to refresh
            return nil
          end
        rescue ex : JSON::ParseException
          cred = self.getCred()
          self.refreshToken(cred["token"])
        end
      else
        sleep 5
        self.checkAndRefresh
      end
    end
  end

  def self.getCred
    credentials = YAML.parse File.read(CREDENTIALS_FILE)
    return credentials.as_h
  end

  def self.writeCred(cred : Hash(YAML::Type, YAML::Type))
    credentials = cred.to_yaml
    File.write(CREDENTIALS_FILE, credentials)
  end

  def self.createPlaylist
    result = @@sApi.post("/users/#{@@myId}/playlists",
      {"Content-Type" => "application/json"},
      {
        "name"   => DEFAULT_PLAYLIST_NAME,
        "public" => "true",
      })
    begin
      album = Spotify::AlbumResponse.from_json(result)
      return album.id
    rescue ex : JSON::ParseException
      puts "ERROR: Unable to create playlist: #{ex}"
    end
    ""
  end

  def self.savePlaylist(id : String)
    credentials = self.getCred
    credentials["playlist"] = id
    self.writeCred(credentials)
    @@playlistId = id
  end

  self.run
end
