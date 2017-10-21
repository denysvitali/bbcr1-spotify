require "./Album"
require "./Artist"
module Spotify
  class Track
    JSON.mapping(
      album: Album,
      artists: Array(Artist),
      available_markets: Array(String),
      disc_number: Int32,
      duration_ms: Int32,
      explicit: Bool,
      external_ids: Hash(String, String),
      external_urls: Hash(String, String),
      href: String,
      id: String,
      name: String,
      popularity: Int32,
      preview_url: {type: String, nilable: true},
      track_number: Int32,
      type: String,
      uri: String
    )
  end
end
