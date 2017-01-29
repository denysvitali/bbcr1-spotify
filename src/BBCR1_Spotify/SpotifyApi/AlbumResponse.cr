module Spotify
  class AlbumResponse
    JSON.mapping(
      collaborative: Bool,
      description: String | Nil,
      external_urls: Hash(String, String),
      followers: Hash(String, JSON::Any),
      name: String,
      id: String,
      public: Bool,
      tracks: Hash(String, JSON::Any),
      type: String,
      uri: String
    )
  end
end
