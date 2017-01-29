# bbcr1-spotify

Crystal app that adds every played song from BBC R1 to a Spotify playlist

## Usage

Warning: the project is still in development!

1. [Create a new application](https://developer.spotify.com/my-applications/) on Spotify.com
2. Put your client_id and client_secret in /credentials.yml
3. Run `crystal run src/BBCR1_Spotify.cr`
4. Follow on screen instructions (you have to follow a link, accept the authorization and you're good to go!)
5. Every song that is found will be put in a playlist named "BBCR1 Songs", you can rename the playlist any time, make it public or private directly from Spotify. This won't affect the normal behavior of this application.

## Development

TODO: Write development instructions here

## Contributing

1. Fork it ( https://github.com/denysvitali/bbcr1-spotify/fork )
2. Create your feature branch (git checkout -b my-new-feature)
3. Commit your changes (git commit -am 'Add some feature')
4. Push to the branch (git push origin my-new-feature)
5. Create a new Pull Request

## Contributors

- [denysvitali](https://github.com/denysvitali) Denys Vitali - creator, maintainer
