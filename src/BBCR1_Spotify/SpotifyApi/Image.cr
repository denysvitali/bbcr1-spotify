module Spotify
  class Image
    JSON.mapping(
      height: Int32,
      width: Int32,
      url: String
    )
  end
end
