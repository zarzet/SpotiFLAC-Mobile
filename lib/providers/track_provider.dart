import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/logger.dart';
import 'package:spotiflac_android/utils/string_utils.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';

final _log = AppLogger('TrackProvider');
const _extensionInitRetryTimeout = Duration(seconds: 30);

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
  final String? headerImageUrl;
  final int? monthlyListeners;
  final List<ArtistAlbum>? artistAlbums;
  final List<Track>? artistTopTracks;
  final List<SearchArtist>? searchArtists;
  final List<SearchAlbum>? searchAlbums;
  final List<SearchPlaylist>? searchPlaylists;
  final bool hasSearchText;
  final bool isShowingRecentAccess;
  final String? searchExtensionId;
  final String? selectedSearchFilter;
  final String? searchSource;

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
    this.searchSource,
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
    String? searchSource,
    bool clearSearchSource = false,
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
      searchSource: clearSearchSource
          ? null
          : (searchSource ?? this.searchSource),
    );
  }
}

class ArtistAlbum {
  final String id;
  final String name;
  final String releaseDate;
  final int totalTracks;
  final String? coverUrl;
  final String albumType;
  final String artists;
  final String? providerId;

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

  bool _isRequestValid(int requestId) => requestId == _currentRequestId;

  bool _usesBuiltInUrlResolver(String url) {
    final normalized = url.toLowerCase();
    return normalized.contains('deezer.com') ||
        normalized.contains('deezer.page.link') ||
        normalized.contains('qobuz.com') ||
        normalized.startsWith('qobuzapp://') ||
        normalized.contains('tidal.com');
  }

  Future<void> fetchFromUrl(String url, {bool useDeezerFallback = true}) async {
    final requestId = ++_currentRequestId;

    state = TrackState(isLoading: true, hasSearchText: state.hasSearchText);

    try {
      var extensionHandler = await PlatformBridge.findURLHandler(url);
      if (extensionHandler == null && !_usesBuiltInUrlResolver(url)) {
        final extensionState = ref.read(extensionProvider);
        if (!extensionState.isInitialized && extensionState.isLoading) {
          _log.i(
            'Extension URL handlers not ready yet, waiting for initialization...',
          );
          await ref
              .read(extensionProvider.notifier)
              .waitForInitialization(timeout: _extensionInitRetryTimeout);
          if (!_isRequestValid(requestId)) return;
          extensionHandler = await PlatformBridge.findURLHandler(url);
        }
      }

      if (extensionHandler != null) {
        _log.i('Found extension URL handler: $extensionHandler for URL: $url');

        Map<String, dynamic>? result;
        for (int attempt = 1; attempt <= 3; attempt++) {
          result = await PlatformBridge.handleURLWithExtension(url);
          if (!_isRequestValid(requestId)) return;

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
            await Future<void>.delayed(const Duration(milliseconds: 500));
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
              albumId:
                  (result['album'] as Map<String, dynamic>?)?['id'] as String?,
              albumName:
                  result['name'] as String? ??
                  (result['album'] as Map<String, dynamic>?)?['name']
                      as String?,
              playlistName: type == 'playlist'
                  ? result['name'] as String?
                  : null,
              coverUrl: normalizeCoverReference(
                result['cover_url']?.toString(),
              ),
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
              coverUrl: normalizeRemoteHttpUrl(
                (artistData['image_url'] ?? artistData['images'])?.toString(),
              ),
              headerImageUrl: normalizeRemoteHttpUrl(
                artistData['header_image']?.toString(),
              ),
              monthlyListeners: artistData['listeners'] as int?,
              artistAlbums: albums,
              artistTopTracks: topTracks.isNotEmpty ? topTracks : null,
              searchExtensionId: extensionId,
            );
            return;
          }
        }
      }

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
            coverUrl: normalizeRemoteHttpUrl(albumInfo['images']?.toString()),
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
            coverUrl: normalizeRemoteHttpUrl(
              playlistInfo['images']?.toString(),
            ),
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
            coverUrl: normalizeRemoteHttpUrl(artistInfo['images']?.toString()),
            artistAlbums: albums,
          );
        }
        return;
      }

      if (url.contains('qobuz.com') || url.startsWith('qobuzapp://')) {
        _log.i('Detected Qobuz URL, parsing...');
        final parsed = await PlatformBridge.parseQobuzUrl(url);
        if (!_isRequestValid(requestId)) return;

        final type = parsed['type'] as String;
        final id = parsed['id'] as String;

        final metadata = await PlatformBridge.getQobuzMetadata(type, id);
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
            albumId: 'qobuz:$id',
            albumName: albumInfo['name'] as String?,
            coverUrl: normalizeRemoteHttpUrl(albumInfo['images']?.toString()),
          );
          _preWarmCacheForTracks(tracks);
        } else if (type == 'playlist') {
          final playlistInfo =
              metadata['playlist_info'] as Map<String, dynamic>;
          final trackList = metadata['track_list'] as List<dynamic>;
          final tracks = trackList
              .map((t) => _parseTrack(t as Map<String, dynamic>))
              .toList();
          final owner = playlistInfo['owner'] as Map<String, dynamic>?;
          final playlistName =
              (playlistInfo['name'] ?? owner?['name']) as String?;
          final coverUrl = normalizeRemoteHttpUrl(
            (playlistInfo['images'] ?? owner?['images'])?.toString(),
          );
          state = TrackState(
            tracks: tracks,
            isLoading: false,
            playlistName: playlistName,
            coverUrl: coverUrl,
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
            coverUrl: normalizeRemoteHttpUrl(artistInfo['images']?.toString()),
            artistAlbums: albums,
          );
        }
        return;
      }

      if (url.contains('tidal.com')) {
        _log.i('Detected Tidal URL, parsing...');
        final parsed = await PlatformBridge.parseTidalUrl(url);
        if (!_isRequestValid(requestId)) return;

        final type = parsed['type'] as String;
        final id = parsed['id'] as String;

        final metadata = await PlatformBridge.getTidalMetadata(type, id);
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
            albumId: 'tidal:$id',
            albumName: albumInfo['name'] as String?,
            coverUrl: normalizeRemoteHttpUrl(albumInfo['images']?.toString()),
          );
          _preWarmCacheForTracks(tracks);
        } else if (type == 'playlist') {
          final playlistInfo =
              metadata['playlist_info'] as Map<String, dynamic>;
          final trackList = metadata['track_list'] as List<dynamic>;
          final tracks = trackList
              .map((t) => _parseTrack(t as Map<String, dynamic>))
              .toList();
          final owner = playlistInfo['owner'] as Map<String, dynamic>?;
          final playlistName =
              (playlistInfo['name'] ?? owner?['name']) as String?;
          final coverUrl = normalizeRemoteHttpUrl(
            (playlistInfo['images'] ?? owner?['images'])?.toString(),
          );
          state = TrackState(
            tracks: tracks,
            isLoading: false,
            playlistName: playlistName,
            coverUrl: coverUrl,
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
            coverUrl: normalizeRemoteHttpUrl(artistInfo['images']?.toString()),
            artistAlbums: albums,
          );
        }
        return;
      }

      state = TrackState(
        isLoading: false,
        error: 'url_not_recognized',
        hasSearchText: state.hasSearchText,
      );
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
    String? filterOverride,
    String? builtInSearchProvider,
  }) async {
    final requestId = ++_currentRequestId;
    final currentFilter = filterOverride ?? state.selectedSearchFilter;
    final requestFilter = currentFilter == 'all' ? null : currentFilter;
    final settings = ref.read(settingsProvider);
    final extensionState = ref.read(extensionProvider);

    String? resolvedProvider = builtInSearchProvider;
    if (resolvedProvider == null || resolvedProvider.isEmpty) {
      final explicitProvider = settings.searchProvider?.trim();
      if (explicitProvider != null && explicitProvider.isNotEmpty) {
        resolvedProvider = explicitProvider;
      } else {
        resolvedProvider =
            extensionState.extensions
                .where(
                  (ext) =>
                      ext.enabled &&
                      ext.hasCustomSearch &&
                      ext.searchBehavior?.primary == true,
                )
                .map((ext) => ext.id)
                .firstOrNull ??
            extensionState.extensions
                .where((ext) => ext.enabled && ext.hasCustomSearch)
                .map((ext) => ext.id)
                .firstOrNull;
      }
      resolvedProvider ??= 'tidal';
    }

    final isEnabledExtensionProvider =
        resolvedProvider.isNotEmpty &&
        extensionState.extensions.any(
          (ext) => ext.enabled && ext.id == resolvedProvider,
        );

    if (resolvedProvider.isNotEmpty &&
        resolvedProvider != 'tidal' &&
        resolvedProvider != 'qobuz' &&
        !isEnabledExtensionProvider &&
        settings.searchProvider?.trim() == resolvedProvider) {
      ref.read(settingsProvider.notifier).setSearchProvider(null);
      resolvedProvider =
          extensionState.extensions
              .where(
                (ext) =>
                    ext.enabled &&
                    ext.hasCustomSearch &&
                    ext.searchBehavior?.primary == true,
              )
              .map((ext) => ext.id)
              .firstOrNull ??
          extensionState.extensions
              .where((ext) => ext.enabled && ext.hasCustomSearch)
              .map((ext) => ext.id)
              .firstOrNull;
      resolvedProvider ??= 'tidal';
    }

    if (resolvedProvider.isNotEmpty &&
        resolvedProvider != 'tidal' &&
        resolvedProvider != 'qobuz' &&
        extensionState.extensions.any(
          (ext) => ext.enabled && ext.id == resolvedProvider,
        )) {
      final resolvedFilter = requestFilter ?? 'track';
      Map<String, dynamic>? options;
      options = {'filter': resolvedFilter};
      await customSearch(
        resolvedProvider,
        query,
        options: options,
        selectedFilter: resolvedFilter,
      );
      return;
    }

    final effectiveBuiltInProvider =
        resolvedProvider == 'tidal' || resolvedProvider == 'qobuz'
        ? resolvedProvider
        : (builtInSearchProvider?.isNotEmpty == true
              ? builtInSearchProvider
              : 'tidal');

    if (effectiveBuiltInProvider == null || effectiveBuiltInProvider.isEmpty) {
      state = TrackState(
        isLoading: false,
        error: 'No active search provider available',
        hasSearchText: state.hasSearchText,
        isShowingRecentAccess: state.isShowingRecentAccess,
        selectedSearchFilter: currentFilter,
      );
      return;
    }

    state = TrackState(
      isLoading: true,
      hasSearchText: state.hasSearchText,
      isShowingRecentAccess: state.isShowingRecentAccess,
      selectedSearchFilter: currentFilter,
    );

    try {
      final hasActiveMetadataExtensions = extensionState.extensions.any(
        (e) => e.enabled && e.hasMetadataProvider,
      );
      final includeExtensions =
          settings.useExtensionProviders && hasActiveMetadataExtensions;

      final effectiveProvider = effectiveBuiltInProvider;

      _log.i(
        'Search started: provider=$effectiveProvider, query="$query", includeExtensions=$includeExtensions, filter=$requestFilter',
      );

      Map<String, dynamic> results;
      List<Map<String, dynamic>> metadataTrackResults = [];

      switch (effectiveProvider) {
        case 'tidal':
          _log.d('Calling Tidal search API...');
          results = await PlatformBridge.searchTidalAll(
            query,
            trackLimit: 20,
            artistLimit: 2,
            filter: requestFilter,
          );
          break;
        case 'qobuz':
          _log.d('Calling Qobuz search API...');
          results = await PlatformBridge.searchQobuzAll(
            query,
            trackLimit: 20,
            artistLimit: 2,
            filter: requestFilter,
          );
          break;
        default:
          _log.d('Calling metadata provider track search API...');
          metadataTrackResults =
              await PlatformBridge.searchTracksWithMetadataProviders(
                query,
                limit: 20,
                includeExtensions: includeExtensions,
              );
          results = const <String, List<dynamic>>{
            'tracks': <dynamic>[],
            'artists': <dynamic>[],
            'albums': <dynamic>[],
            'playlists': <dynamic>[],
          };
          break;
      }
      _log.i(
        '$effectiveProvider returned ${(results['tracks'] as List?)?.length ?? 0} tracks, ${(results['artists'] as List?)?.length ?? 0} artists, ${(results['albums'] as List?)?.length ?? 0} albums',
      );

      if (!_isRequestValid(requestId)) {
        _log.w('Search request cancelled (requestId=$requestId)');
        return;
      }

      final trackList = results['tracks'] as List<dynamic>? ?? [];
      final artistList = results['artists'] as List<dynamic>? ?? [];
      final albumList = results['albums'] as List<dynamic>? ?? [];
      final trackSearchResults = metadataTrackResults.isNotEmpty
          ? metadataTrackResults
          : trackList.whereType<Map<String, dynamic>>().toList();

      _log.d(
        'Raw results: ${trackSearchResults.length} tracks, ${artistList.length} artists, ${albumList.length} albums',
      );

      final tracks = <Track>[];

      for (int i = 0; i < trackSearchResults.length; i++) {
        final t = trackSearchResults[i];
        try {
          tracks.add(_parseSearchTrack(t));
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
        'Search complete: ${tracks.length} tracks, ${artists.length} artists, ${albums.length} albums, ${playlists.length} playlists parsed successfully',
      );

      state = TrackState(
        tracks: tracks,
        searchArtists: artists,
        searchAlbums: albums,
        searchPlaylists: playlists,
        isLoading: false,
        hasSearchText: state.hasSearchText,
        isShowingRecentAccess: state.isShowingRecentAccess,
        selectedSearchFilter: currentFilter,
        searchSource: effectiveProvider,
      );
    } catch (e, stackTrace) {
      if (!_isRequestValid(requestId)) return;
      _log.e('Search failed: $e', e, stackTrace);
      state = TrackState(
        isLoading: false,
        error: e.toString(),
        hasSearchText: state.hasSearchText,
        isShowingRecentAccess: state.isShowingRecentAccess,
        selectedSearchFilter: currentFilter,
      );
    }
  }

  Future<void> customSearch(
    String extensionId,
    String query, {
    Map<String, dynamic>? options,
    String? selectedFilter,
  }) async {
    final requestId = ++_currentRequestId;
    final currentFilter = selectedFilter ?? state.selectedSearchFilter;

    state = TrackState(
      isLoading: true,
      hasSearchText: state.hasSearchText,
      isShowingRecentAccess: state.isShowingRecentAccess,
      selectedSearchFilter: currentFilter,
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
        isShowingRecentAccess: state.isShowingRecentAccess,
        searchExtensionId: extensionId,
        selectedSearchFilter: currentFilter,
      );
    } catch (e, stackTrace) {
      if (!_isRequestValid(requestId)) return;
      _log.e('Custom search failed: $e', e, stackTrace);
      state = TrackState(
        isLoading: false,
        error: e.toString(),
        hasSearchText: state.hasSearchText,
        isShowingRecentAccess: state.isShowingRecentAccess,
        selectedSearchFilter: currentFilter,
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
        artistId: track.artistId,
        albumId: track.albumId,
        coverUrl: track.coverUrl,
        isrc: track.isrc,
        duration: track.duration,
        trackNumber: track.trackNumber,
        discNumber: track.discNumber,
        releaseDate: track.releaseDate,
        albumType: track.albumType,
        totalTracks: track.totalTracks,
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
    } catch (_) {}
  }

  void clear() {
    state = const TrackState();
  }

  void setSearchFilter(String? filter) {
    if (state.selectedSearchFilter == filter) return;
    state = state.copyWith(
      selectedSearchFilter: filter,
      clearSelectedSearchFilter: filter == null,
    );
  }

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
      isShowingRecentAccess: state.isShowingRecentAccess,
    );
  }

  Track _parseTrack(Map<String, dynamic> data) {
    final durationMs = _extractDurationMs(data);
    final spotifyId = (data['spotify_id'] ?? '').toString();
    final nativeId = (data['id'] ?? '').toString();
    return Track(
      id: spotifyId.isNotEmpty ? spotifyId : nativeId,
      name: data['name'] as String? ?? '',
      artistName: data['artists'] as String? ?? '',
      albumName: data['album_name'] as String? ?? '',
      albumArtist: data['album_artist'] as String?,
      artistId: (data['artist_id'] ?? data['artistId'])?.toString(),
      albumId: data['album_id']?.toString(),
      coverUrl: normalizeCoverReference(data['images']?.toString()),
      isrc: data['isrc'] as String?,
      duration: (durationMs / 1000).round(),
      trackNumber: data['track_number'] as int?,
      discNumber: data['disc_number'] as int?,
      totalDiscs: data['total_discs'] as int?,
      releaseDate: data['release_date'] as String?,
      albumType: normalizeOptionalString(data['album_type']?.toString()),
      totalTracks: data['total_tracks'] as int?,
      composer: data['composer']?.toString(),
    );
  }

  Track _parseSearchTrack(Map<String, dynamic> data, {String? source}) {
    final durationMs = _extractDurationMs(data);

    final itemType = data['item_type']?.toString();
    final effectiveSource =
        source ?? data['source']?.toString() ?? data['provider_id']?.toString();
    final spotifyId = (data['spotify_id'] ?? '').toString();
    final nativeId = (data['id'] ?? '').toString();
    final preferredId = effectiveSource != null && effectiveSource.isNotEmpty
        ? (nativeId.isNotEmpty ? nativeId : spotifyId)
        : (spotifyId.isNotEmpty ? spotifyId : nativeId);

    return Track(
      id: preferredId,
      name: (data['name'] ?? '').toString(),
      artistName: (data['artists'] ?? data['artist'] ?? '').toString(),
      albumName: (data['album_name'] ?? data['album'] ?? '').toString(),
      albumArtist: data['album_artist']?.toString(),
      artistId: (data['artist_id'] ?? data['artistId'])?.toString(),
      albumId: data['album_id']?.toString(),
      coverUrl: normalizeCoverReference(
        (data['cover_url'] ?? data['images'])?.toString(),
      ),
      isrc: data['isrc']?.toString(),
      duration: (durationMs / 1000).round(),
      trackNumber: data['track_number'] as int?,
      discNumber: data['disc_number'] as int?,
      totalDiscs: data['total_discs'] as int?,
      releaseDate: data['release_date']?.toString(),
      totalTracks: data['total_tracks'] as int?,
      source: effectiveSource,
      albumType: normalizeOptionalString(data['album_type']?.toString()),
      composer: data['composer']?.toString(),
      itemType: itemType,
    );
  }

  int _extractDurationMs(Map<String, dynamic> data) {
    final durationMsRaw = data['duration_ms'];
    if (durationMsRaw is num && durationMsRaw > 0) {
      return durationMsRaw.toInt();
    }
    if (durationMsRaw is String) {
      final parsed = num.tryParse(durationMsRaw.trim());
      if (parsed != null && parsed > 0) {
        return parsed.toInt();
      }
    }

    final durationSecRaw = data['duration'];
    if (durationSecRaw is num && durationSecRaw > 0) {
      return (durationSecRaw * 1000).toInt();
    }
    if (durationSecRaw is String) {
      final parsed = num.tryParse(durationSecRaw.trim());
      if (parsed != null && parsed > 0) {
        return (parsed * 1000).toInt();
      }
    }

    return 0;
  }

  ArtistAlbum _parseArtistAlbum(Map<String, dynamic> data) {
    return ArtistAlbum(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      releaseDate: data['release_date'] as String? ?? '',
      totalTracks: data['total_tracks'] as int? ?? 0,
      coverUrl: normalizeCoverReference(
        (data['cover_url'] ?? data['images'])?.toString(),
      ),
      albumType: data['album_type'] as String? ?? 'album',
      artists: data['artists'] as String? ?? '',
      providerId: data['provider_id']?.toString(),
    );
  }

  SearchArtist _parseSearchArtist(Map<String, dynamic> data) {
    return SearchArtist(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      imageUrl: normalizeRemoteHttpUrl(data['images']?.toString()),
      followers: data['followers'] as int? ?? 0,
      popularity: data['popularity'] as int? ?? 0,
    );
  }

  SearchAlbum _parseSearchAlbum(Map<String, dynamic> data) {
    return SearchAlbum(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      artists: data['artists'] as String? ?? '',
      imageUrl: normalizeRemoteHttpUrl(data['images']?.toString()),
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
      imageUrl: normalizeRemoteHttpUrl(data['images']?.toString()),
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
        'spotify_id': track.id,
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
