import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';

class TrackState {
  final List<Track> tracks;
  final bool isLoading;
  final String? error;
  final String? albumName;
  final String? playlistName;
  final String? artistName;
  final String? coverUrl;
  final List<ArtistAlbum>? artistAlbums; // For artist page
  final TrackState? previousState; // For back navigation

  const TrackState({
    this.tracks = const [],
    this.isLoading = false,
    this.error,
    this.albumName,
    this.playlistName,
    this.artistName,
    this.coverUrl,
    this.artistAlbums,
    this.previousState,
  });

  bool get canGoBack => previousState != null;
  
  bool get hasContent => tracks.isNotEmpty || artistAlbums != null;

  TrackState copyWith({
    List<Track>? tracks,
    bool? isLoading,
    String? error,
    String? albumName,
    String? playlistName,
    String? artistName,
    String? coverUrl,
    List<ArtistAlbum>? artistAlbums,
    TrackState? previousState,
    bool clearPreviousState = false,
  }) {
    return TrackState(
      tracks: tracks ?? this.tracks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      albumName: albumName ?? this.albumName,
      playlistName: playlistName ?? this.playlistName,
      artistName: artistName ?? this.artistName,
      coverUrl: coverUrl ?? this.coverUrl,
      artistAlbums: artistAlbums ?? this.artistAlbums,
      previousState: clearPreviousState ? null : (previousState ?? this.previousState),
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

class TrackNotifier extends Notifier<TrackState> {
  @override
  TrackState build() {
    return const TrackState();
  }

  Future<void> fetchFromUrl(String url) async {
    // Save current state for back navigation (only if we have content or it's empty)
    final savedState = state.hasContent ? TrackState(
      tracks: state.tracks,
      albumName: state.albumName,
      playlistName: state.playlistName,
      artistName: state.artistName,
      coverUrl: state.coverUrl,
      artistAlbums: state.artistAlbums,
      previousState: state.previousState,
    ) : const TrackState(); // Empty state for back to home

    state = TrackState(isLoading: true, previousState: savedState);

    try {
      final parsed = await PlatformBridge.parseSpotifyUrl(url);
      final type = parsed['type'] as String;

      final metadata = await PlatformBridge.getSpotifyMetadata(url);

      if (type == 'track') {
        final trackData = metadata['track'] as Map<String, dynamic>;
        final track = _parseTrack(trackData);
        state = TrackState(
          tracks: [track],
          isLoading: false,
          coverUrl: track.coverUrl,
          previousState: savedState,
        );
      } else if (type == 'album') {
        final albumInfo = metadata['album_info'] as Map<String, dynamic>;
        final trackList = metadata['track_list'] as List<dynamic>;
        final tracks = trackList.map((t) => _parseTrack(t as Map<String, dynamic>)).toList();
        state = TrackState(
          tracks: tracks,
          isLoading: false,
          albumName: albumInfo['name'] as String?,
          coverUrl: albumInfo['images'] as String?,
          previousState: savedState,
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
          previousState: savedState,
        );
      } else if (type == 'artist') {
        final artistInfo = metadata['artist_info'] as Map<String, dynamic>;
        final albumsList = metadata['albums'] as List<dynamic>;
        final albums = albumsList.map((a) => _parseArtistAlbum(a as Map<String, dynamic>)).toList();
        state = TrackState(
          tracks: [], // No tracks for artist view
          isLoading: false,
          artistName: artistInfo['name'] as String?,
          coverUrl: artistInfo['images'] as String?,
          artistAlbums: albums,
          previousState: savedState,
        );
      }
    } catch (e) {
      state = TrackState(isLoading: false, error: e.toString(), previousState: savedState);
    }
  }

  Future<void> search(String query) async {
    // Save current state for back navigation
    final savedState = state.hasContent ? TrackState(
      tracks: state.tracks,
      albumName: state.albumName,
      playlistName: state.playlistName,
      artistName: state.artistName,
      coverUrl: state.coverUrl,
      artistAlbums: state.artistAlbums,
      previousState: state.previousState,
    ) : const TrackState();

    state = TrackState(isLoading: true, previousState: savedState);

    try {
      final results = await PlatformBridge.searchSpotify(query, limit: 20);
      final trackList = results['tracks'] as List<dynamic>? ?? [];
      final tracks = trackList.map((t) => _parseSearchTrack(t as Map<String, dynamic>)).toList();
      state = TrackState(
        tracks: tracks,
        isLoading: false,
        previousState: savedState,
      );
    } catch (e) {
      state = TrackState(isLoading: false, error: e.toString(), previousState: savedState);
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

  /// Go back to previous state (if available)
  bool goBack() {
    if (state.previousState != null) {
      state = state.previousState!;
      return true;
    }
    return false;
  }

  /// Fetch album from artist view - saves current artist state for back navigation
  Future<void> fetchAlbumFromArtist(String albumId) async {
    // Save current artist state before fetching album
    final savedState = TrackState(
      artistName: state.artistName,
      coverUrl: state.coverUrl,
      artistAlbums: state.artistAlbums,
      previousState: state.previousState, // Keep the chain
    );

    state = TrackState(
      isLoading: true,
      previousState: savedState,
    );

    try {
      final url = 'https://open.spotify.com/album/$albumId';
      final metadata = await PlatformBridge.getSpotifyMetadata(url);
      
      final albumInfo = metadata['album_info'] as Map<String, dynamic>;
      final trackList = metadata['track_list'] as List<dynamic>;
      final tracks = trackList.map((t) => _parseTrack(t as Map<String, dynamic>)).toList();
      
      state = TrackState(
        tracks: tracks,
        isLoading: false,
        albumName: albumInfo['name'] as String?,
        coverUrl: albumInfo['images'] as String?,
        previousState: savedState,
      );
    } catch (e) {
      state = TrackState(
        isLoading: false,
        error: e.toString(),
        previousState: savedState,
      );
    }
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
}

final trackProvider = NotifierProvider<TrackNotifier, TrackState>(
  TrackNotifier.new,
);
