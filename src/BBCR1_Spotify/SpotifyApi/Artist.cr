module Spotify
  class Artist
    JSON.mapping(
      external_urls: Hash(String, String),
      href: String,
      id: String,
      name: String,
      type: String,
      uri: String
    )
  end
end
