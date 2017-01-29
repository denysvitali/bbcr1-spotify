module Spotify
  class TokenResponse
    JSON.mapping(
      access_token: String,
      token_type: String,
      expires_in: Int32,
      refresh_token: String | Nil,
      scope: String
    )
  end
end
