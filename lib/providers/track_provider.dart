import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';

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

  Future<void> fetchFromUrl(String url) async {
    // Increment request ID to cancel any pending requests
    final requestId = ++_currentRequestId;

    // Preserve hasSearchText during fetch
    state = TrackState(isLoading: true, hasSearchText: state.hasSearchText);

    try {
      final parsed = await PlatformBridge.parseSpotifyUrl(url);
      if (!_isRequestValid(requestId)) return; // Request cancelled
      
      final type = parsed['type'] as String;

      final metadata = await PlatformBridge.getSpotifyMetadata(url);
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

  Future<void> search(String query) async {
    // Increment request ID to cancel any pending requests
    final requestId = ++_currentRequestId;

    // Preserve hasSearchText during search
    state = TrackState(isLoading: true, hasSearchText: state.hasSearchText);

    try {
      final results = await PlatformBridge.searchSpotifyAll(query, trackLimit: 20, artistLimit: 5);
      if (!_isRequestValid(requestId)) return; // Request cancelled
      
      final trackList = results['tracks'] as List<dynamic>? ?? [];
      final artistList = results['artists'] as List<dynamic>? ?? [];
      
      final tracks = trackList.map((t) => _parseSearchTrack(t as Map<String, dynamic>)).toList();
      final artists = artistList.map((a) => _parseSearchArtist(a as Map<String, dynamic>)).toList();
      
      state = TrackState(
        tracks: tracks,
        searchArtists: artists,
        isLoading: false,
        hasSearchText: state.hasSearchText,
      );
    } catch (e) {
      if (!_isRequestValid(requestId)) return; // Request cancelled
      // Preserve hasSearchText on error so user stays on search screen
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
      duration: data['duration_ms'] as int? ?? 0,
      trackNumber: data['track_number'] as int?,
      discNumber: data['disc_number'] as int?,
      releaseDate: data['release_date'] as String?,
    );
  }

  Track _parseSearchTrack(Map<String, dynamic> data) {
    return Track(
      id: data['spotify_id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      artistName: data['artists'] as String? ?? '',
      albumName: data['album_name'] as String? ?? '',
      albumArtist: data['album_artist'] as String?,
      coverUrl: data['images'] as String?,
      isrc: data['isrc'] as String?,
      duration: data['duration_ms'] as int? ?? 0,
      trackNumber: data['track_number'] as int?,
      discNumber: data['disc_number'] as int?,
      releaseDate: data['release_date'] as String?,
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
}

final trackProvider = NotifierProvider<TrackNotifier, TrackState>(
  TrackNotifier.new,
);
