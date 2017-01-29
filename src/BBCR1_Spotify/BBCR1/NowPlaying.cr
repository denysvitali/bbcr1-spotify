module BBCR1
  class NowPlaying
    JSON.mapping(
      requestMinSeconds: Int32,
      requestMaxSeconds: Int32,
      realtime: Playing
    )
  end

  class Playing
    JSON.mapping(
      type: String,
      start: Int32,
      end: Int32,
      artist: String,
      title: String,
      segment_event_pid: String,
      record_id: String,
      seconds_ago: Int32,
      musicbrainz_artist: {type: Hash(String, String), nilable: true},
      version_pid: String,
      episode_pid: String,
      brand_pid: String,
      programme_offset: Int32
    )
  end
end
