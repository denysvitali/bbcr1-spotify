require "yaml"
module BBCR1_Spotify
  class Credentials
    YAML.mapping(
      client_id: String,
      client_secret: String,
      token: Token,
      playlist: {type: String, nilable: true}
    )
    class Token
      YAML.mapping(
        access_token: {type: String, nilable: true},
        refresh_token: {type: String, nilable: true}
      )
    end
  end
end
