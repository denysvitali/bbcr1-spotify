require "./TracksResult"
module Spotify
  class SearchResult
    JSON.mapping(
      tracks: TracksResult
    )
  end
end
