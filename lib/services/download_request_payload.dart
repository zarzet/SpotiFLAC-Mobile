class DownloadRequestPayload {
  final String isrc;
  final String service;
  final String spotifyId;
  final String trackName;
  final String artistName;
  final String albumName;
  final String albumArtist;
  final String coverUrl;
  final String outputDir;
  final String filenameFormat;
  final String quality;
  final bool embedLyrics;
  final bool embedMaxQualityCover;
  final int trackNumber;
  final int discNumber;
  final int totalTracks;
  final String releaseDate;
  final String itemId;
  final int durationMs;
  final String source;
  final String genre;
  final String label;
  final String copyright;
  final String tidalId;
  final String qobuzId;
  final String deezerId;
  final String lyricsMode;
  final bool useExtensions;
  final bool useFallback;
  final String storageMode;
  final String safTreeUri;
  final String safRelativeDir;
  final String safFileName;
  final String safOutputExt;

  const DownloadRequestPayload({
    this.isrc = '',
    this.service = '',
    this.spotifyId = '',
    required this.trackName,
    required this.artistName,
    required this.albumName,
    this.albumArtist = '',
    this.coverUrl = '',
    required this.outputDir,
    required this.filenameFormat,
    this.quality = 'LOSSLESS',
    this.embedLyrics = true,
    this.embedMaxQualityCover = true,
    this.trackNumber = 1,
    this.discNumber = 1,
    this.totalTracks = 1,
    this.releaseDate = '',
    this.itemId = '',
    this.durationMs = 0,
    this.source = '',
    this.genre = '',
    this.label = '',
    this.copyright = '',
    this.tidalId = '',
    this.qobuzId = '',
    this.deezerId = '',
    this.lyricsMode = 'embed',
    this.useExtensions = false,
    this.useFallback = false,
    this.storageMode = 'app',
    this.safTreeUri = '',
    this.safRelativeDir = '',
    this.safFileName = '',
    this.safOutputExt = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'isrc': isrc,
      'service': service,
      'spotify_id': spotifyId,
      'track_name': trackName,
      'artist_name': artistName,
      'album_name': albumName,
      'album_artist': albumArtist,
      'cover_url': coverUrl,
      'output_dir': outputDir,
      'filename_format': filenameFormat,
      'quality': quality,
      'embed_lyrics': embedLyrics,
      'embed_max_quality_cover': embedMaxQualityCover,
      'track_number': trackNumber,
      'disc_number': discNumber,
      'total_tracks': totalTracks,
      'release_date': releaseDate,
      'item_id': itemId,
      'duration_ms': durationMs,
      'source': source,
      'genre': genre,
      'label': label,
      'copyright': copyright,
      'tidal_id': tidalId,
      'qobuz_id': qobuzId,
      'deezer_id': deezerId,
      'lyrics_mode': lyricsMode,
      'use_extensions': useExtensions,
      'use_fallback': useFallback,
      'storage_mode': storageMode,
      'saf_tree_uri': safTreeUri,
      'saf_relative_dir': safRelativeDir,
      'saf_file_name': safFileName,
      'saf_output_ext': safOutputExt,
    };
  }

  DownloadRequestPayload withStrategy({
    bool? useExtensions,
    bool? useFallback,
  }) {
    return DownloadRequestPayload(
      isrc: isrc,
      service: service,
      spotifyId: spotifyId,
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      albumArtist: albumArtist,
      coverUrl: coverUrl,
      outputDir: outputDir,
      filenameFormat: filenameFormat,
      quality: quality,
      embedLyrics: embedLyrics,
      embedMaxQualityCover: embedMaxQualityCover,
      trackNumber: trackNumber,
      discNumber: discNumber,
      totalTracks: totalTracks,
      releaseDate: releaseDate,
      itemId: itemId,
      durationMs: durationMs,
      source: source,
      genre: genre,
      label: label,
      copyright: copyright,
      tidalId: tidalId,
      qobuzId: qobuzId,
      deezerId: deezerId,
      lyricsMode: lyricsMode,
      useExtensions: useExtensions ?? this.useExtensions,
      useFallback: useFallback ?? this.useFallback,
      storageMode: storageMode,
      safTreeUri: safTreeUri,
      safRelativeDir: safRelativeDir,
      safFileName: safFileName,
      safOutputExt: safOutputExt,
    );
  }
}
