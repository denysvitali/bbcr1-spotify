require "./Track"
module Spotify
  class TracksResult
    JSON.mapping(
      href: String,
      items: Array(Track),
      limit: Int32,
      next: {type: String, nilable: true},
      offset: Int32,
      previous: {type: String, nilable: true},
      total: Int32
    )
  end
end
