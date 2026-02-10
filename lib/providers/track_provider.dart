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
  final String? headerImageUrl; // Artist header image for background
  final int? monthlyListeners; // Artist monthly listeners
  final List<ArtistAlbum>? artistAlbums; // For artist page
  final List<Track>? artistTopTracks; // Artist's popular tracks
  final List<SearchArtist>? searchArtists; // For search results
  final List<SearchAlbum>? searchAlbums; // For search results (albums)
  final List<SearchPlaylist>? searchPlaylists; // For search results (playlists)
  final bool hasSearchText; // For back button handling
  final bool isShowingRecentAccess; // For recent access mode
  final String?
  searchExtensionId; // Extension ID used for current search results
  final String?
  selectedSearchFilter; // Currently selected search filter (e.g., "track", "album", "artist", "playlist")

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
    this.headerImageUrl,
    this.monthlyListeners,
    this.artistAlbums,
    this.artistTopTracks,
    this.searchArtists,
    this.searchAlbums,
    this.searchPlaylists,
    this.hasSearchText = false,
    this.isShowingRecentAccess = false,
    this.searchExtensionId,
    this.selectedSearchFilter,
  });

  bool get hasContent =>
      tracks.isNotEmpty ||
      artistAlbums != null ||
      (searchArtists != null && searchArtists!.isNotEmpty) ||
      (searchAlbums != null && searchAlbums!.isNotEmpty) ||
      (searchPlaylists != null && searchPlaylists!.isNotEmpty);

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
    String? headerImageUrl,
    int? monthlyListeners,
    List<ArtistAlbum>? artistAlbums,
    List<Track>? artistTopTracks,
    List<SearchArtist>? searchArtists,
    List<SearchAlbum>? searchAlbums,
    List<SearchPlaylist>? searchPlaylists,
    bool? hasSearchText,
    bool? isShowingRecentAccess,
    String? searchExtensionId,
    String? selectedSearchFilter,
    bool clearSelectedSearchFilter = false,
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
      headerImageUrl: headerImageUrl ?? this.headerImageUrl,
      monthlyListeners: monthlyListeners ?? this.monthlyListeners,
      artistAlbums: artistAlbums ?? this.artistAlbums,
      artistTopTracks: artistTopTracks ?? this.artistTopTracks,
      searchArtists: searchArtists ?? this.searchArtists,
      searchAlbums: searchAlbums ?? this.searchAlbums,
      searchPlaylists: searchPlaylists ?? this.searchPlaylists,
      hasSearchText: hasSearchText ?? this.hasSearchText,
      isShowingRecentAccess:
          isShowingRecentAccess ?? this.isShowingRecentAccess,
      searchExtensionId: searchExtensionId,
      selectedSearchFilter: clearSelectedSearchFilter
          ? null
          : (selectedSearchFilter ?? this.selectedSearchFilter),
    );
  }
}

class ArtistAlbum {
  final String id;
  final String name;
  final String releaseDate;
  final int totalTracks;
  final String? coverUrl;
  final String albumType; // album, single, compilation
  final String artists;
  final String? providerId; // Extension ID if from extension

  const ArtistAlbum({
    required this.id,
    required this.name,
    required this.releaseDate,
    required this.totalTracks,
    this.coverUrl,
    required this.albumType,
    required this.artists,
    this.providerId,
  });
}

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

class SearchAlbum {
  final String id;
  final String name;
  final String artists;
  final String? imageUrl;
  final String? releaseDate;
  final int totalTracks;
  final String albumType;

  const SearchAlbum({
    required this.id,
    required this.name,
    required this.artists,
    this.imageUrl,
    this.releaseDate,
    required this.totalTracks,
    required this.albumType,
  });
}

class SearchPlaylist {
  final String id;
  final String name;
  final String owner;
  final String? imageUrl;
  final int totalTracks;

  const SearchPlaylist({
    required this.id,
    required this.name,
    required this.owner,
    this.imageUrl,
    required this.totalTracks,
  });
}

class TrackNotifier extends Notifier<TrackState> {
  int _currentRequestId = 0;
  static const int _maxPreWarmTracksPerRequest = 80;

  @override
  TrackState build() {
    return const TrackState();
  }

  /// Check if request is still valid (not cancelled by newer request)
  bool _isRequestValid(int requestId) => requestId == _currentRequestId;

  Future<void> fetchFromUrl(String url, {bool useDeezerFallback = true}) async {
    final requestId = ++_currentRequestId;

    state = TrackState(isLoading: true, hasSearchText: state.hasSearchText);

    try {
      // Step 1: Check for extension URL handlers first (handles YT Music, etc.)
      final extensionHandler = await PlatformBridge.findURLHandler(url);
      if (extensionHandler != null) {
        _log.i('Found extension URL handler: $extensionHandler for URL: $url');

        // Retry logic for extension URL handlers (up to 3 attempts)
        Map<String, dynamic>? result;
        for (int attempt = 1; attempt <= 3; attempt++) {
          result = await PlatformBridge.handleURLWithExtension(url);
          if (!_isRequestValid(requestId)) return;

          // Check if we got valid data
          if (result != null &&
              result['type'] == 'track' &&
              result['track'] != null) {
            final trackData = result['track'] as Map<String, dynamic>;
            final name = trackData['name']?.toString() ?? '';
            if (name.isNotEmpty) {
              break;
            }
          } else if (result != null &&
              (result['type'] == 'album' || result['type'] == 'playlist')) {
            break;
          } else if (result != null && result['type'] == 'artist') {
            break;
          }

          if (attempt < 3) {
            await Future.delayed(const Duration(milliseconds: 500));
          }
        }

        if (result != null) {
          final type = result['type'] as String?;
          final extensionId = result['extension_id'] as String?;

          if (type == 'track' && result['track'] != null) {
            final trackData = result['track'] as Map<String, dynamic>;
            final track = _parseSearchTrack(trackData, source: extensionId);

            if (track.name.isEmpty) {
              state = TrackState(
                isLoading: false,
                error: 'Failed to load track metadata from extension',
              );
              return;
            }

            state = TrackState(
              tracks: [track],
              isLoading: false,
              coverUrl: track.coverUrl,
              searchExtensionId: extensionId,
            );
            return;
          } else if ((type == 'album' || type == 'playlist') &&
              result['tracks'] != null) {
            final trackList = result['tracks'] as List<dynamic>;
            final tracks = trackList
                .map(
                  (t) => _parseSearchTrack(
                    t as Map<String, dynamic>,
                    source: extensionId,
                  ),
                )
                .toList();
            state = TrackState(
              tracks: tracks,
              isLoading: false,
              albumId: result['album']?['id'] as String?,
              albumName:
                  result['name'] as String? ??
                  result['album']?['name'] as String?,
              playlistName: type == 'playlist'
                  ? result['name'] as String?
                  : null,
              coverUrl: result['cover_url'] as String?,
              searchExtensionId: extensionId,
            );
            return;
          } else if (type == 'artist' && result['artist'] != null) {
            final artistData = result['artist'] as Map<String, dynamic>;
            final albumsList = artistData['albums'] as List<dynamic>? ?? [];
            final albums = albumsList
                .map((a) => _parseArtistAlbum(a as Map<String, dynamic>))
                .toList();

            final topTracksList =
                artistData['top_tracks'] as List<dynamic>? ?? [];
            final topTracks = topTracksList
                .map(
                  (t) => _parseSearchTrack(
                    t as Map<String, dynamic>,
                    source: extensionId,
                  ),
                )
                .toList();

            state = TrackState(
              tracks: [],
              isLoading: false,
              artistId: artistData['id'] as String?,
              artistName: artistData['name'] as String?,
              coverUrl:
                  artistData['image_url'] as String? ??
                  artistData['images'] as String?,
              headerImageUrl: artistData['header_image'] as String?,
              monthlyListeners: artistData['listeners'] as int?,
              artistAlbums: albums,
              artistTopTracks: topTracks.isNotEmpty ? topTracks : null,
              searchExtensionId: extensionId,
            );
            return;
          }
        }
      }

      // Step 2: Try Deezer URL parsing
      if (url.contains('deezer.com') || url.contains('deezer.page.link')) {
        _log.i('Detected Deezer URL, parsing...');
        final parsed = await PlatformBridge.parseDeezerUrl(url);
        if (!_isRequestValid(requestId)) return;

        final type = parsed['type'] as String;
        final id = parsed['id'] as String;

        final metadata = await PlatformBridge.getDeezerMetadata(type, id);
        if (!_isRequestValid(requestId)) return;

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
          final tracks = trackList
              .map((t) => _parseTrack(t as Map<String, dynamic>))
              .toList();
          state = TrackState(
            tracks: tracks,
            isLoading: false,
            albumId: id,
            albumName: albumInfo['name'] as String?,
            coverUrl: albumInfo['images'] as String?,
          );
          _preWarmCacheForTracks(tracks);
        } else if (type == 'playlist') {
          final playlistInfo =
              metadata['playlist_info'] as Map<String, dynamic>;
          final trackList = metadata['track_list'] as List<dynamic>;
          final tracks = trackList
              .map((t) => _parseTrack(t as Map<String, dynamic>))
              .toList();
          state = TrackState(
            tracks: tracks,
            isLoading: false,
            playlistName: playlistInfo['name'] as String?,
            coverUrl: playlistInfo['images'] as String?,
          );
          _preWarmCacheForTracks(tracks);
        } else if (type == 'artist') {
          final artistInfo = metadata['artist_info'] as Map<String, dynamic>;
          final albumsList = metadata['albums'] as List<dynamic>;
          final albums = albumsList
              .map((a) => _parseArtistAlbum(a as Map<String, dynamic>))
              .toList();
          state = TrackState(
            tracks: [],
            isLoading: false,
            artistId: artistInfo['id'] as String?,
            artistName: artistInfo['name'] as String?,
            coverUrl: artistInfo['images'] as String?,
            artistAlbums: albums,
          );
        }
        return;
      }

      // Step 3: Try Tidal URL parsing
      if (url.contains('tidal.com')) {
        _log.i('Detected Tidal URL, parsing...');
        final parsed = await PlatformBridge.parseTidalUrl(url);
        if (!_isRequestValid(requestId)) return;

        final type = parsed['type'] as String;
        final id = parsed['id'] as String;

        _log.i('Tidal URL parsed: type=$type, id=$id');

        // For track URLs, convert to Spotify/Deezer and fetch metadata from there
        if (type == 'track') {
          try {
            _log.i('Converting Tidal track to Spotify/Deezer via SongLink...');
            final conversion = await PlatformBridge.convertTidalToSpotifyDeezer(
              url,
            );
            if (!_isRequestValid(requestId)) return;

            final spotifyUrl = conversion['spotify_url'] as String?;
            final deezerUrl = conversion['deezer_url'] as String?;

            if (spotifyUrl != null && spotifyUrl.isNotEmpty) {
              _log.i('Found Spotify URL: $spotifyUrl, fetching metadata...');
              final metadata =
                  await PlatformBridge.getSpotifyMetadataWithFallback(
                    spotifyUrl,
                  );
              if (!_isRequestValid(requestId)) return;

              final trackData = metadata['track'] as Map<String, dynamic>;
              final track = _parseTrack(trackData);
              state = TrackState(
                tracks: [track],
                isLoading: false,
                coverUrl: track.coverUrl,
              );
              return;
            } else if (deezerUrl != null && deezerUrl.isNotEmpty) {
              _log.i('Found Deezer URL: $deezerUrl, fetching metadata...');
              final deezerParsed = await PlatformBridge.parseDeezerUrl(
                deezerUrl,
              );
              final metadata = await PlatformBridge.getDeezerMetadata(
                'track',
                deezerParsed['id'] as String,
              );
              if (!_isRequestValid(requestId)) return;

              final trackData = metadata['track'] as Map<String, dynamic>;
              final track = _parseTrack(trackData);
              state = TrackState(
                tracks: [track],
                isLoading: false,
                coverUrl: track.coverUrl,
              );
              return;
            }
          } catch (e) {
            _log.w('Failed to convert Tidal URL via SongLink: $e');
          }
        }

        // For album/artist/playlist, not yet supported
        state = TrackState(
          isLoading: false,
          error:
              'Tidal $type links are not fully supported yet. Only track links work via SongLink conversion.',
          hasSearchText: state.hasSearchText,
        );
        return;
      }

      // Step 4: Fall back to Spotify parsing
      final parsed = await PlatformBridge.parseSpotifyUrl(url);
      if (!_isRequestValid(requestId)) return;

      final type = parsed['type'] as String;

      Map<String, dynamic> metadata;

      try {
        metadata = await PlatformBridge.getSpotifyMetadataWithFallback(url);
      } catch (e) {
        rethrow;
      }

      if (!_isRequestValid(requestId)) return;

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
        final tracks = trackList
            .map((t) => _parseTrack(t as Map<String, dynamic>))
            .toList();
        state = TrackState(
          tracks: tracks,
          isLoading: false,
          albumId: parsed['id'] as String?,
          albumName: albumInfo['name'] as String?,
          coverUrl: albumInfo['images'] as String?,
        );
        _preWarmCacheForTracks(tracks);
      } else if (type == 'playlist') {
        final playlistInfo = metadata['playlist_info'] as Map<String, dynamic>;
        final trackList = metadata['track_list'] as List<dynamic>;
        final tracks = trackList
            .map((t) => _parseTrack(t as Map<String, dynamic>))
            .toList();
        final owner = playlistInfo['owner'] as Map<String, dynamic>?;
        state = TrackState(
          tracks: tracks,
          isLoading: false,
          playlistName: owner?['name'] as String?,
          coverUrl: owner?['images'] as String?,
        );
        _preWarmCacheForTracks(tracks);
      } else if (type == 'artist') {
        final artistInfo = metadata['artist_info'] as Map<String, dynamic>;
        final albumsList = metadata['albums'] as List<dynamic>;
        final albums = albumsList
            .map((a) => _parseArtistAlbum(a as Map<String, dynamic>))
            .toList();
        state = TrackState(
          tracks: [],
          isLoading: false,
          artistId: artistInfo['id'] as String?,
          artistName: artistInfo['name'] as String?,
          coverUrl: artistInfo['images'] as String?,
          artistAlbums: albums,
        );
      }
    } catch (e) {
      if (!_isRequestValid(requestId)) return;
      state = TrackState(
        isLoading: false,
        error: e.toString(),
        hasSearchText: state.hasSearchText,
      );
    }
  }

  Future<void> search(
    String query, {
    String? metadataSource,
    String? filterOverride,
  }) async {
    final requestId = ++_currentRequestId;

    // Preserve selected filter during loading
    final currentFilter = filterOverride ?? state.selectedSearchFilter;

    state = TrackState(
      isLoading: true,
      hasSearchText: state.hasSearchText,
      selectedSearchFilter: currentFilter,
    );

    try {
      final settings = ref.read(settingsProvider);
      final extensionState = ref.read(extensionProvider);
      final hasActiveMetadataExtensions = extensionState.extensions.any(
        (e) => e.enabled && e.hasMetadataProvider,
      );
      final searchProvider = settings.searchProvider;
      final useExtensions =
          settings.useExtensionProviders &&
          hasActiveMetadataExtensions &&
          searchProvider != null &&
          searchProvider.isNotEmpty;

      final source = metadataSource ?? 'deezer';

      _log.i(
        'Search started: source=$source, query="$query", useExtensions=$useExtensions, filter=$currentFilter',
      );

      Map<String, dynamic> results;
      List<Track> extensionTracks = [];

      if (useExtensions) {
        try {
          _log.d('Calling extension search API...');
          final extResults = await PlatformBridge.searchTracksWithExtensions(
            query,
            limit: 20,
          );
          _log.i('Extensions returned ${extResults.length} tracks');

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

      if (source == 'deezer') {
        _log.d('Calling Deezer search API...');
        results = await PlatformBridge.searchDeezerAll(
          query,
          trackLimit: 20,
          artistLimit: 2,
          filter: currentFilter,
        );
        _log.i(
          'Deezer returned ${(results['tracks'] as List?)?.length ?? 0} tracks, ${(results['artists'] as List?)?.length ?? 0} artists, ${(results['albums'] as List?)?.length ?? 0} albums',
        );
      } else {
        _log.d('Calling Spotify search API...');
        results = await PlatformBridge.searchSpotifyAll(
          query,
          trackLimit: 20,
          artistLimit: 2,
        );
        _log.i(
          'Spotify returned ${(results['tracks'] as List?)?.length ?? 0} tracks, ${(results['artists'] as List?)?.length ?? 0} artists',
        );
      }

      if (!_isRequestValid(requestId)) {
        _log.w('Search request cancelled (requestId=$requestId)');
        return;
      }

      final trackList = results['tracks'] as List<dynamic>? ?? [];
      final artistList = results['artists'] as List<dynamic>? ?? [];
      final albumList = results['albums'] as List<dynamic>? ?? [];

      _log.d(
        'Raw results: ${trackList.length} tracks, ${artistList.length} artists, ${albumList.length} albums',
      );

      final tracks = <Track>[];

      tracks.addAll(extensionTracks);

      final existingIsrcs = extensionTracks
          .where((t) => t.isrc != null && t.isrc!.isNotEmpty)
          .map((t) => t.isrc!)
          .toSet();

      for (int i = 0; i < trackList.length; i++) {
        final t = trackList[i];
        try {
          if (t is Map<String, dynamic>) {
            final track = _parseSearchTrack(t);
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

      final albums = <SearchAlbum>[];
      for (int i = 0; i < albumList.length; i++) {
        final a = albumList[i];
        try {
          if (a is Map<String, dynamic>) {
            albums.add(_parseSearchAlbum(a));
          } else {
            _log.w('Album[$i] is not a Map: ${a.runtimeType}');
          }
        } catch (e) {
          _log.e('Failed to parse album[$i]: $e', e);
        }
      }

      final playlistList = results['playlists'] as List<dynamic>? ?? [];
      final playlists = <SearchPlaylist>[];
      for (int i = 0; i < playlistList.length; i++) {
        final p = playlistList[i];
        try {
          if (p is Map<String, dynamic>) {
            playlists.add(_parseSearchPlaylist(p));
          } else {
            _log.w('Playlist[$i] is not a Map: ${p.runtimeType}');
          }
        } catch (e) {
          _log.e('Failed to parse playlist[$i]: $e', e);
        }
      }

      _log.i(
        'Search complete: ${tracks.length} tracks (${extensionTracks.length} from extensions), ${artists.length} artists, ${albums.length} albums, ${playlists.length} playlists parsed successfully',
      );

      state = TrackState(
        tracks: tracks,
        searchArtists: artists,
        searchAlbums: albums,
        searchPlaylists: playlists,
        isLoading: false,
        hasSearchText: state.hasSearchText,
        selectedSearchFilter: currentFilter, // Preserve filter in results
      );
    } catch (e, stackTrace) {
      if (!_isRequestValid(requestId)) return;
      _log.e('Search failed: $e', e, stackTrace);
      state = TrackState(
        isLoading: false,
        error: e.toString(),
        hasSearchText: state.hasSearchText,
        selectedSearchFilter: currentFilter,
      );
    }
  }

  Future<void> customSearch(
    String extensionId,
    String query, {
    Map<String, dynamic>? options,
  }) async {
    final requestId = ++_currentRequestId;

    state = TrackState(
      isLoading: true,
      hasSearchText: state.hasSearchText,
      selectedSearchFilter:
          state.selectedSearchFilter, // Preserve filter during loading
    );

    try {
      _log.i('Custom search started: extension=$extensionId, query="$query"');

      final results = await PlatformBridge.customSearchWithExtension(
        extensionId,
        query,
        options: options,
      );

      if (!_isRequestValid(requestId)) {
        _log.w('Custom search request cancelled (requestId=$requestId)');
        return;
      }

      _log.i('Custom search returned ${results.length} tracks');

      final tracks = <Track>[];
      for (int i = 0; i < results.length; i++) {
        final t = results[i];
        try {
          tracks.add(_parseSearchTrack(t, source: extensionId));
        } catch (e) {
          _log.e('Failed to parse custom search track[$i]: $e', e);
        }
      }

      _log.i(
        'Custom search complete: ${tracks.length} tracks parsed (source=$extensionId)',
      );

      state = TrackState(
        tracks: tracks,
        searchArtists: [],
        isLoading: false,
        hasSearchText: state.hasSearchText,
        searchExtensionId: extensionId, // Store which extension was used
        selectedSearchFilter:
            state.selectedSearchFilter, // Preserve selected filter
      );
    } catch (e, stackTrace) {
      if (!_isRequestValid(requestId)) return;
      _log.e('Custom search failed: $e', e, stackTrace);
      state = TrackState(
        isLoading: false,
        error: e.toString(),
        hasSearchText: state.hasSearchText,
      );
    }
  }

  Future<void> checkAvailability(int index) async {
    if (index < 0 || index >= state.tracks.length) return;

    final track = state.tracks[index];
    if (track.isrc == null || track.isrc!.isEmpty) return;

    try {
      final availability = await PlatformBridge.checkAvailability(
        track.id,
        track.isrc!,
      );
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
        albumType: track.albumType,
        source: track.source,
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
    } catch (_) {
      // Silently ignore update failures - track may have been removed
    }
  }

  void clear() {
    state = const TrackState();
  }

  /// Set selected search filter for extension search
  void setSearchFilter(String? filter) {
    if (state.selectedSearchFilter == filter) return;
    state = state.copyWith(
      selectedSearchFilter: filter,
      clearSelectedSearchFilter: filter == null,
    );
  }

  /// Set search text state for back button handling
  void setSearchText(bool hasText) {
    if (state.hasSearchText == hasText) {
      return;
    }
    state = state.copyWith(hasSearchText: hasText);
  }

  void setShowingRecentAccess(bool showing) {
    if (state.isShowingRecentAccess == showing) {
      return;
    }
    state = state.copyWith(isShowingRecentAccess: showing);
  }

  /// Set tracks from a collection (album/playlist) opened from search results
  void setTracksFromCollection({
    required List<Track> tracks,
    String? albumName,
    String? playlistName,
    String? coverUrl,
  }) {
    state = TrackState(
      tracks: tracks,
      isLoading: false,
      albumName: albumName,
      playlistName: playlistName,
      coverUrl: coverUrl,
      hasSearchText: state.hasSearchText,
    );
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
    int durationMs = 0;
    final durationValue = data['duration_ms'];
    if (durationValue is int) {
      durationMs = durationValue;
    } else if (durationValue is double) {
      durationMs = durationValue.toInt();
    }

    final itemType = data['item_type']?.toString();

    return Track(
      id: (data['spotify_id'] ?? data['id'] ?? '').toString(),
      name: (data['name'] ?? '').toString(),
      artistName: (data['artists'] ?? data['artist'] ?? '').toString(),
      albumName: (data['album_name'] ?? data['album'] ?? '').toString(),
      albumArtist: data['album_artist']?.toString(),
      coverUrl: (data['cover_url'] ?? data['images'])?.toString(),
      isrc: data['isrc']?.toString(),
      duration: (durationMs / 1000).round(),
      trackNumber: data['track_number'] as int?,
      discNumber: data['disc_number'] as int?,
      releaseDate: data['release_date']?.toString(),
      source:
          source ??
          data['source']?.toString() ??
          data['provider_id']?.toString(),
      albumType: data['album_type']?.toString(),
      itemType: itemType,
    );
  }

  ArtistAlbum _parseArtistAlbum(Map<String, dynamic> data) {
    return ArtistAlbum(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      releaseDate: data['release_date'] as String? ?? '',
      totalTracks: data['total_tracks'] as int? ?? 0,
      coverUrl: (data['cover_url'] ?? data['images'])?.toString(),
      albumType: data['album_type'] as String? ?? 'album',
      artists: data['artists'] as String? ?? '',
      providerId: data['provider_id']?.toString(),
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

  SearchAlbum _parseSearchAlbum(Map<String, dynamic> data) {
    return SearchAlbum(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      artists: data['artists'] as String? ?? '',
      imageUrl: data['images'] as String?,
      releaseDate: data['release_date'] as String?,
      totalTracks: data['total_tracks'] as int? ?? 0,
      albumType: data['album_type'] as String? ?? 'album',
    );
  }

  SearchPlaylist _parseSearchPlaylist(Map<String, dynamic> data) {
    return SearchPlaylist(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      owner: data['owner'] as String? ?? '',
      imageUrl: data['images'] as String?,
      totalTracks: data['total_tracks'] as int? ?? 0,
    );
  }

  void _preWarmCacheForTracks(List<Track> tracks) {
    if (tracks.isEmpty) return;
    final cacheRequests = <Map<String, String>>[];
    for (final track in tracks) {
      final isrc = track.isrc;
      if (isrc == null || isrc.isEmpty) {
        continue;
      }
      cacheRequests.add({
        'isrc': isrc,
        'track_name': track.name,
        'artist_name': track.artistName,
        'spotify_id': track.id, // Include Spotify ID for Amazon lookup
        'service': 'tidal',
      });
      if (cacheRequests.length >= _maxPreWarmTracksPerRequest) {
        break;
      }
    }
    if (cacheRequests.isEmpty) return;

    PlatformBridge.preWarmTrackCache(cacheRequests).catchError((_) {});
  }
}

final trackProvider = NotifierProvider<TrackNotifier, TrackState>(
  TrackNotifier.new,
);
