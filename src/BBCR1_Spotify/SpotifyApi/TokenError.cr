module Spotify
  class TokenError
    JSON.mapping(
      error: String,
      error_description: String | Nil
    )
  end
end
