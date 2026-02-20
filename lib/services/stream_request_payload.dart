class StreamRequestPayload {
  final String service;
  final String spotifyId;
  final String isrc;
  final String trackName;
  final String artistName;
  final String albumName;
  final String quality;
  final String source;
  final String tidalId;
  final String qobuzId;
  final String deezerId;
  final int durationMs;
  final bool useExtensions;
  final bool useFallback;
  final String songLinkRegion;

  const StreamRequestPayload({
    this.service = '',
    this.spotifyId = '',
    this.isrc = '',
    required this.trackName,
    required this.artistName,
    this.albumName = '',
    this.quality = 'LOSSLESS',
    this.source = '',
    this.tidalId = '',
    this.qobuzId = '',
    this.deezerId = '',
    this.durationMs = 0,
    this.useExtensions = false,
    this.useFallback = false,
    this.songLinkRegion = 'US',
  });

  Map<String, dynamic> toJson() {
    return {
      'service': service,
      'spotify_id': spotifyId,
      'isrc': isrc,
      'track_name': trackName,
      'artist_name': artistName,
      'album_name': albumName,
      'quality': quality,
      'source': source,
      'tidal_id': tidalId,
      'qobuz_id': qobuzId,
      'deezer_id': deezerId,
      'duration_ms': durationMs,
      'use_extensions': useExtensions,
      'use_fallback': useFallback,
      'songlink_region': songLinkRegion,
    };
  }
}
