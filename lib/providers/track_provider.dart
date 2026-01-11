import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/logger.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';

final _log = AppLogger('TrackProvider');

class TrackState {
  final List<Track> tracks;
  final bool isLoading;
  final String? error;
  final String? albumId;
  final String? albumName;
  final String? playlistName;
  final String? artistId;
  final String? artistName;
  final String? coverUrl;
  final List<ArtistAlbum>? artistAlbums; // For artist page
  final List<SearchArtist>? searchArtists; // For search results
  final bool hasSearchText; // For back button handling
  final String? searchExtensionId; // Extension ID used for current search results

  const TrackState({
    this.tracks = const [],
    this.isLoading = false,
    this.error,
    this.albumId,
    this.albumName,
    this.playlistName,
    this.artistId,
    this.artistName,
    this.coverUrl,
    this.artistAlbums,
    this.searchArtists,
    this.hasSearchText = false,
    this.searchExtensionId,
  });

  bool get hasContent => tracks.isNotEmpty || artistAlbums != null || (searchArtists != null && searchArtists!.isNotEmpty);

  TrackState copyWith({
    List<Track>? tracks,
    bool? isLoading,
    String? error,
    String? albumId,
    String? albumName,
    String? playlistName,
    String? artistId,
    String? artistName,
    String? coverUrl,
    List<ArtistAlbum>? artistAlbums,
    List<SearchArtist>? searchArtists,
    bool? hasSearchText,
    String? searchExtensionId,
  }) {
    return TrackState(
      tracks: tracks ?? this.tracks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      albumId: albumId ?? this.albumId,
      albumName: albumName ?? this.albumName,
      playlistName: playlistName ?? this.playlistName,
      artistId: artistId ?? this.artistId,
      artistName: artistName ?? this.artistName,
      coverUrl: coverUrl ?? this.coverUrl,
      artistAlbums: artistAlbums ?? this.artistAlbums,
      searchArtists: searchArtists ?? this.searchArtists,
      hasSearchText: hasSearchText ?? this.hasSearchText,
      searchExtensionId: searchExtensionId,
    );
  }
}

/// Represents an album in artist discography
class ArtistAlbum {
  final String id;
  final String name;
  final String releaseDate;
  final int totalTracks;
  final String? coverUrl;
  final String albumType; // album, single, compilation
  final String artists;

  const ArtistAlbum({
    required this.id,
    required this.name,
    required this.releaseDate,
    required this.totalTracks,
    this.coverUrl,
    required this.albumType,
    required this.artists,
  });
}

/// Represents an artist in search results
class SearchArtist {
  final String id;
  final String name;
  final String? imageUrl;
  final int followers;
  final int popularity;

  const SearchArtist({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.followers,
    required this.popularity,
  });
}

class TrackNotifier extends Notifier<TrackState> {
  /// Request ID to track and cancel outdated requests
  int _currentRequestId = 0;

  @override
  TrackState build() {
    return const TrackState();
  }

  /// Check if request is still valid (not cancelled by newer request)
  bool _isRequestValid(int requestId) => requestId == _currentRequestId;

  Future<void> fetchFromUrl(String url, {bool useDeezerFallback = true}) async {
    // Increment request ID to cancel any pending requests
    final requestId = ++_currentRequestId;

    // Preserve hasSearchText during fetch
    state = TrackState(isLoading: true, hasSearchText: state.hasSearchText);

    try {
      final parsed = await PlatformBridge.parseSpotifyUrl(url);
      if (!_isRequestValid(requestId)) return; // Request cancelled
      
      final type = parsed['type'] as String;

      // Use the new fallback-enabled method
      Map<String, dynamic> metadata;
      
      try {
        // ignore: avoid_print
        print('[FetchURL] Fetching $type with Deezer fallback enabled...');
        metadata = await PlatformBridge.getSpotifyMetadataWithFallback(url);
        // ignore: avoid_print
        print('[FetchURL] Metadata fetch success');
      } catch (e) {
        // If fallback also fails, show error
        // ignore: avoid_print
        print('[FetchURL] Metadata fetch failed: $e');
        rethrow;
      }
      
      if (!_isRequestValid(requestId)) return; // Request cancelled

      if (type == 'track') {
        final trackData = metadata['track'] as Map<String, dynamic>;
        final track = _parseTrack(trackData);
        state = TrackState(
          tracks: [track],
          isLoading: false,
          coverUrl: track.coverUrl,
        );
      } else if (type == 'album') {
        final albumInfo = metadata['album_info'] as Map<String, dynamic>;
        final trackList = metadata['track_list'] as List<dynamic>;
        final tracks = trackList.map((t) => _parseTrack(t as Map<String, dynamic>)).toList();
        state = TrackState(
          tracks: tracks,
          isLoading: false,
          albumId: parsed['id'] as String?,
          albumName: albumInfo['name'] as String?,
          coverUrl: albumInfo['images'] as String?,
        );
        // Pre-warm cache for album tracks in background
        _preWarmCacheForTracks(tracks);
      } else if (type == 'playlist') {
        final playlistInfo = metadata['playlist_info'] as Map<String, dynamic>;
        final trackList = metadata['track_list'] as List<dynamic>;
        final tracks = trackList.map((t) => _parseTrack(t as Map<String, dynamic>)).toList();
        final owner = playlistInfo['owner'] as Map<String, dynamic>?;
        state = TrackState(
          tracks: tracks,
          isLoading: false,
          playlistName: owner?['name'] as String?,
          coverUrl: owner?['images'] as String?,
        );
        // Pre-warm cache for playlist tracks in background
        _preWarmCacheForTracks(tracks);
      } else if (type == 'artist') {
        final artistInfo = metadata['artist_info'] as Map<String, dynamic>;
        final albumsList = metadata['albums'] as List<dynamic>;
        final albums = albumsList.map((a) => _parseArtistAlbum(a as Map<String, dynamic>)).toList();
        state = TrackState(
          tracks: [], // No tracks for artist view
          isLoading: false,
          artistId: artistInfo['id'] as String?,
          artistName: artistInfo['name'] as String?,
          coverUrl: artistInfo['images'] as String?,
          artistAlbums: albums,
        );
      }
    } catch (e) {
      if (!_isRequestValid(requestId)) return; // Request cancelled
      // Preserve hasSearchText on error so user stays on search screen
      state = TrackState(isLoading: false, error: e.toString(), hasSearchText: state.hasSearchText);
    }
  }

  Future<void> search(String query, {String? metadataSource}) async {
    // Increment request ID to cancel any pending requests
    final requestId = ++_currentRequestId;

    // Preserve hasSearchText during search
    state = TrackState(isLoading: true, hasSearchText: state.hasSearchText);

    try {
      // Check if extension providers should be used for search
      final settings = ref.read(settingsProvider);
      final extensionState = ref.read(extensionProvider);
      final hasActiveMetadataExtensions = extensionState.extensions.any(
        (e) => e.enabled && e.hasMetadataProvider,
      );
      final useExtensions = settings.useExtensionProviders && hasActiveMetadataExtensions;

      // Use Deezer or Spotify based on settings
      final source = metadataSource ?? 'deezer';
      
      _log.i('Search started: source=$source, query="$query", useExtensions=$useExtensions');
      
      Map<String, dynamic> results;
      List<Track> extensionTracks = [];
      
      // Try extension providers first if enabled
      if (useExtensions) {
        try {
          _log.d('Calling extension search API...');
          final extResults = await PlatformBridge.searchTracksWithExtensions(query, limit: 20);
          _log.i('Extensions returned ${extResults.length} tracks');
          
          // Parse extension results
          for (final t in extResults) {
            try {
              extensionTracks.add(_parseSearchTrack(t));
            } catch (e) {
              _log.e('Failed to parse extension track: $e', e);
            }
          }
        } catch (e) {
          _log.w('Extension search failed, falling back to built-in: $e');
        }
      }
      
      // Also search with built-in providers
      if (source == 'deezer') {
        _log.d('Calling Deezer search API...');
        results = await PlatformBridge.searchDeezerAll(query, trackLimit: 20, artistLimit: 5);
        _log.i('Deezer returned ${(results['tracks'] as List?)?.length ?? 0} tracks, ${(results['artists'] as List?)?.length ?? 0} artists');
      } else {
        _log.d('Calling Spotify search API...');
        results = await PlatformBridge.searchSpotifyAll(query, trackLimit: 20, artistLimit: 5);
        _log.i('Spotify returned ${(results['tracks'] as List?)?.length ?? 0} tracks, ${(results['artists'] as List?)?.length ?? 0} artists');
      }
      
      if (!_isRequestValid(requestId)) {
        _log.w('Search request cancelled (requestId=$requestId)');
        return;
      }
      
      final trackList = results['tracks'] as List<dynamic>? ?? [];
      final artistList = results['artists'] as List<dynamic>? ?? [];
      
      _log.d('Raw results: ${trackList.length} tracks, ${artistList.length} artists');
      
      // Parse tracks with error handling per item
      final tracks = <Track>[];
      
      // Add extension tracks first (they have priority)
      tracks.addAll(extensionTracks);
      
      // Add built-in provider tracks, avoiding duplicates by ISRC
      final existingIsrcs = extensionTracks
          .where((t) => t.isrc != null && t.isrc!.isNotEmpty)
          .map((t) => t.isrc!)
          .toSet();
      
      for (int i = 0; i < trackList.length; i++) {
        final t = trackList[i];
        try {
          if (t is Map<String, dynamic>) {
            final track = _parseSearchTrack(t);
            // Skip if we already have this track from extensions
            if (track.isrc != null && existingIsrcs.contains(track.isrc)) {
              continue;
            }
            tracks.add(track);
          } else {
            _log.w('Track[$i] is not a Map: ${t.runtimeType}');
          }
        } catch (e) {
          _log.e('Failed to parse track[$i]: $e', e);
        }
      }
      
      // Parse artists with error handling per item
      final artists = <SearchArtist>[];
      for (int i = 0; i < artistList.length; i++) {
        final a = artistList[i];
        try {
          if (a is Map<String, dynamic>) {
            artists.add(_parseSearchArtist(a));
          } else {
            _log.w('Artist[$i] is not a Map: ${a.runtimeType}');
          }
        } catch (e) {
          _log.e('Failed to parse artist[$i]: $e', e);
        }
      }
      
      _log.i('Search complete: ${tracks.length} tracks (${extensionTracks.length} from extensions), ${artists.length} artists parsed successfully');
      
      state = TrackState(
        tracks: tracks,
        searchArtists: artists,
        isLoading: false,
        hasSearchText: state.hasSearchText,
      );
    } catch (e, stackTrace) {
      if (!_isRequestValid(requestId)) return;
      _log.e('Search failed: $e', e, stackTrace);
      state = TrackState(isLoading: false, error: e.toString(), hasSearchText: state.hasSearchText);
    }
  }

  /// Perform custom search using a specific extension
  Future<void> customSearch(String extensionId, String query, {Map<String, dynamic>? options}) async {
    // Increment request ID to cancel any pending requests
    final requestId = ++_currentRequestId;

    // Preserve hasSearchText during search
    state = TrackState(isLoading: true, hasSearchText: state.hasSearchText);

    try {
      _log.i('Custom search started: extension=$extensionId, query="$query"');
      
      final results = await PlatformBridge.customSearchWithExtension(extensionId, query, options: options);
      
      if (!_isRequestValid(requestId)) {
        _log.w('Custom search request cancelled (requestId=$requestId)');
        return;
      }
      
      _log.i('Custom search returned ${results.length} tracks');
      
      // Parse tracks with error handling per item, setting source to extension ID
      final tracks = <Track>[];
      for (int i = 0; i < results.length; i++) {
        final t = results[i];
        try {
          tracks.add(_parseSearchTrack(t, source: extensionId));
        } catch (e) {
          _log.e('Failed to parse custom search track[$i]: $e', e);
        }
      }
      
      _log.i('Custom search complete: ${tracks.length} tracks parsed (source=$extensionId)');
      
      state = TrackState(
        tracks: tracks,
        searchArtists: [], // Custom search doesn't return artists
        isLoading: false,
        hasSearchText: state.hasSearchText,
        searchExtensionId: extensionId, // Store which extension was used
      );
    } catch (e, stackTrace) {
      if (!_isRequestValid(requestId)) return;
      _log.e('Custom search failed: $e', e, stackTrace);
      state = TrackState(isLoading: false, error: e.toString(), hasSearchText: state.hasSearchText);
    }
  }

  Future<void> checkAvailability(int index) async {
    if (index < 0 || index >= state.tracks.length) return;

    final track = state.tracks[index];
    if (track.isrc == null || track.isrc!.isEmpty) return;

    try {
      final availability = await PlatformBridge.checkAvailability(track.id, track.isrc!);
      final updatedTrack = Track(
        id: track.id,
        name: track.name,
        artistName: track.artistName,
        albumName: track.albumName,
        albumArtist: track.albumArtist,
        coverUrl: track.coverUrl,
        isrc: track.isrc,
        duration: track.duration,
        trackNumber: track.trackNumber,
        discNumber: track.discNumber,
        releaseDate: track.releaseDate,
        availability: ServiceAvailability(
          tidal: availability['tidal'] as bool? ?? false,
          qobuz: availability['qobuz'] as bool? ?? false,
          amazon: availability['amazon'] as bool? ?? false,
          tidalUrl: availability['tidal_url'] as String?,
          qobuzUrl: availability['qobuz_url'] as String?,
          amazonUrl: availability['amazon_url'] as String?,
        ),
      );

      final tracks = List<Track>.from(state.tracks);
      tracks[index] = updatedTrack;
      state = state.copyWith(tracks: tracks);
    } catch (e) {
      // Silently fail availability check
    }
  }

  void clear() {
    state = const TrackState();
  }

  /// Set search text state for back button handling
  void setSearchText(bool hasText) {
    state = state.copyWith(hasSearchText: hasText);
  }

  Track _parseTrack(Map<String, dynamic> data) {
    return Track(
      id: data['spotify_id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      artistName: data['artists'] as String? ?? '',
      albumName: data['album_name'] as String? ?? '',
      albumArtist: data['album_artist'] as String?,
      coverUrl: data['images'] as String?,
      isrc: data['isrc'] as String?,
      duration: ((data['duration_ms'] as int? ?? 0) / 1000).round(),
      trackNumber: data['track_number'] as int?,
      discNumber: data['disc_number'] as int?,
      releaseDate: data['release_date'] as String?,
    );
  }

  Track _parseSearchTrack(Map<String, dynamic> data, {String? source}) {
    // Handle duration_ms which might be int or double
    int durationMs = 0;
    final durationValue = data['duration_ms'];
    if (durationValue is int) {
      durationMs = durationValue;
    } else if (durationValue is double) {
      durationMs = durationValue.toInt();
    }
    
    return Track(
      id: (data['spotify_id'] ?? data['id'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      artistName: (data['artists'] ?? data['artist'] ?? '').toString(),
      albumName: (data['album_name'] ?? data['album'] ?? '').toString(),
      albumArtist: data['album_artist']?.toString(),
      coverUrl: data['images']?.toString(),
      isrc: data['isrc']?.toString(),
      duration: (durationMs / 1000).round(),
      trackNumber: data['track_number'] as int?,
      discNumber: data['disc_number'] as int?,
      releaseDate: data['release_date']?.toString(),
      source: source ?? data['source']?.toString() ?? data['provider_id']?.toString(),
    );
  }

  ArtistAlbum _parseArtistAlbum(Map<String, dynamic> data) {
    return ArtistAlbum(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      releaseDate: data['release_date'] as String? ?? '',
      totalTracks: data['total_tracks'] as int? ?? 0,
      coverUrl: data['images'] as String?,
      albumType: data['album_type'] as String? ?? 'album',
      artists: data['artists'] as String? ?? '',
    );
  }

  SearchArtist _parseSearchArtist(Map<String, dynamic> data) {
    return SearchArtist(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      imageUrl: data['images'] as String?,
      followers: data['followers'] as int? ?? 0,
      popularity: data['popularity'] as int? ?? 0,
    );
  }

  /// Pre-warm track ID cache for faster downloads
  /// Runs in background, doesn't block UI
  void _preWarmCacheForTracks(List<Track> tracks) {
    // Only pre-warm if we have tracks with ISRC
    final tracksWithIsrc = tracks.where((t) => t.isrc != null && t.isrc!.isNotEmpty).toList();
    if (tracksWithIsrc.isEmpty) return;

    // Build request list for Go backend
    final cacheRequests = tracksWithIsrc.map((t) => {
      'isrc': t.isrc!,
      'track_name': t.name,
      'artist_name': t.artistName,
      'spotify_id': t.id, // Include Spotify ID for Amazon lookup
      'service': 'tidal', // Default to tidal for pre-warming
    }).toList();

    // Fire and forget - runs in background
    PlatformBridge.preWarmTrackCache(cacheRequests).catchError((_) {
      // Silently ignore errors - this is just an optimization
    });
  }
}

final trackProvider = NotifierProvider<TrackNotifier, TrackState>(
  TrackNotifier.new,
);
