module Spotify
  class Album
    JSON.mapping(
      album_type: String,
      artists: Array(Artist),
      available_markets: Array(String),
      external_urls: Hash(String, String),
      href: String,
      id: String,
      images: Array(Image),
      name: String,
      type: String,
      uri: String
    )
  end
end
