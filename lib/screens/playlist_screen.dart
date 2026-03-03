import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/utils/file_access.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/local_library_provider.dart';
import 'package:spotiflac_android/providers/playback_provider.dart';
import 'package:spotiflac_android/widgets/download_service_picker.dart';
import 'package:spotiflac_android/widgets/track_collection_quick_actions.dart';

class PlaylistScreen extends ConsumerStatefulWidget {
  final String playlistName;
  final String? coverUrl;
  final List<Track> tracks;
  final String? playlistId;

  const PlaylistScreen({
    super.key,
    required this.playlistName,
    this.coverUrl,
    required this.tracks,
    this.playlistId,
  });

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  bool _showTitleInAppBar = false;
  final ScrollController _scrollController = ScrollController();
  List<Track>? _fetchedTracks;
  bool _isLoading = false;
  String? _error;

  List<Track> get _tracks => _fetchedTracks ?? widget.tracks;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _fetchTracksIfNeeded();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchTracksIfNeeded() async {
    if (widget.tracks.isNotEmpty || widget.playlistId == null) return;

    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Extract numeric ID from "deezer:123" format
      String playlistId = widget.playlistId!;
      if (playlistId.startsWith('deezer:')) {
        playlistId = playlistId.substring(7);
      }

      final result = await PlatformBridge.getDeezerMetadata(
        'playlist',
        playlistId,
      );
      if (!mounted) return;

      // Go backend returns 'track_list' not 'tracks'
      final trackList = result['track_list'] as List<dynamic>? ?? [];
      final tracks = trackList
          .map((t) => _parseTrack(t as Map<String, dynamic>))
          .toList();

      setState(() {
        _fetchedTracks = tracks;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Track _parseTrack(Map<String, dynamic> data) {
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
      artistId: (data['artist_id'] ?? data['artistId'])?.toString(),
      albumId: data['album_id']?.toString(),
      coverUrl: (data['cover_url'] ?? data['images'])?.toString(),
      isrc: data['isrc']?.toString(),
      duration: (durationMs / 1000).round(),
      trackNumber: data['track_number'] as int?,
      discNumber: data['disc_number'] as int?,
      releaseDate: data['release_date']?.toString(),
    );
  }

  void _onScroll() {
    final expandedHeight = _calculateExpandedHeight(context);
    final shouldShow =
        _scrollController.offset > (expandedHeight - kToolbarHeight - 20);
    if (shouldShow != _showTitleInAppBar) {
      setState(() => _showTitleInAppBar = shouldShow);
    }
  }

  double _calculateExpandedHeight(BuildContext context) {
    final mediaSize = MediaQuery.of(context).size;
    return (mediaSize.height * 0.55).clamp(360.0, 520.0);
  }

  /// Upgrade cover URL to a reasonable resolution for full-screen display.
  String? _highResCoverUrl(String? url) {
    if (url == null) return null;
    // Spotify CDN: upgrade 300 → 640 only
    if (url.contains('ab67616d00001e02')) {
      return url.replaceAll('ab67616d00001e02', 'ab67616d0000b273');
    }
    // Deezer CDN: upgrade to 1000x1000
    final deezerRegex = RegExp(r'/(\d+)x(\d+)-(\d+)-(\d+)-(\d+)-(\d+)\.jpg$');
    if (url.contains('cdn-images.dzcdn.net') && deezerRegex.hasMatch(url)) {
      return url.replaceAllMapped(
        deezerRegex,
        (m) => '/1000x1000-${m[3]}-${m[4]}-${m[5]}-${m[6]}.jpg',
      );
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildAppBar(context, colorScheme),
          _buildInfoCard(context, colorScheme),
          _buildTrackList(context, colorScheme),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    final expandedHeight = _calculateExpandedHeight(context);

    return SliverAppBar(
      expandedHeight: expandedHeight,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showTitleInAppBar ? 1.0 : 0.0,
        child: Text(
          widget.playlistName,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      flexibleSpace: LayoutBuilder(
        builder: (context, constraints) {
          final collapseRatio =
              (constraints.maxHeight - kToolbarHeight) /
              (expandedHeight - kToolbarHeight);
          final showContent = collapseRatio > 0.3;

          return FlexibleSpaceBar(
            collapseMode: CollapseMode.pin,
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Full-screen cover background
                if (widget.coverUrl != null)
                  CachedNetworkImage(
                    imageUrl:
                        _highResCoverUrl(widget.coverUrl) ?? widget.coverUrl!,
                    fit: BoxFit.cover,
                    cacheManager: CoverCacheManager.instance,
                    placeholder: (_, _) =>
                        Container(color: colorScheme.surface),
                    errorWidget: (_, _, _) =>
                        Container(color: colorScheme.surface),
                  )
                else
                  Container(
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(
                      Icons.playlist_play,
                      size: 80,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                // Bottom gradient for readability
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  height: expandedHeight * 0.65,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.85),
                        ],
                      ),
                    ),
                  ),
                ),
                // Playlist info overlay at bottom
                Positioned(
                  left: 20,
                  right: 20,
                  bottom: 40,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 150),
                    opacity: showContent ? 1.0 : 0.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          widget.playlistName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            height: 1.2,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (_tracks.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.playlist_play,
                                  size: 14,
                                  color: Colors.white,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  context.l10n.tracksCount(_tracks.length),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _buildPlayAllButton(),
                              const SizedBox(width: 12),
                              _buildDownloadAllCenterButton(context),
                              const SizedBox(width: 12),
                              _buildShufflePlayButton(),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ],
            ),
            stretchModes: const [StretchMode.zoomBackground],
          );
        },
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.4),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.arrow_back, color: Colors.white),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ColorScheme colorScheme) {
    // Info is now displayed in the full-screen cover overlay
    return const SliverToBoxAdapter(child: SizedBox.shrink());
  }

  Widget _buildTrackList(BuildContext context, ColorScheme colorScheme) {
    if (_isLoading) {
      return const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (_error != null) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Card(
            color: colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: colorScheme.error),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _error!,
                      style: TextStyle(color: colorScheme.error),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    if (_tracks.isEmpty) {
      return SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Center(
            child: Text(
              context.l10n.errorNoTracksFound,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ),
        ),
      );
    }

    return SliverList(
      delegate: SliverChildBuilderDelegate((context, index) {
        final track = _tracks[index];
        return KeyedSubtree(
          key: ValueKey(track.id),
          child: _PlaylistTrackItem(
            track: track,
            tracksList: _tracks,
            onDownload: () => _downloadTrack(context, track),
          ),
        );
      }, childCount: _tracks.length),
    );
  }

  void _downloadTrack(BuildContext context, Track track) {
    final settings = ref.read(settingsProvider);

    if (settings.askQualityBeforeDownload) {
      DownloadServicePicker.show(
        context,
        trackName: track.name,
        artistName: track.artistName,
        coverUrl: track.coverUrl,
        onSelect: (quality, service) {
          ref
              .read(downloadQueueProvider.notifier)
              .addToQueue(track, service, qualityOverride: quality);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(context.l10n.snackbarAddedToQueue(track.name)),
            ),
          );
        },
      );
    } else {
      ref
          .read(downloadQueueProvider.notifier)
          .addToQueue(track, settings.defaultService);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.snackbarAddedToQueue(track.name))),
      );
    }
  }

  // ── Shuffle / Love / Download buttons ──

  Widget _buildCircleButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback? onPressed,
  }) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withValues(alpha: 0.15),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: Colors.white),
        tooltip: tooltip,
        padding: EdgeInsets.zero,
      ),
    );
  }

  Widget _buildPlayAllButton() {
    return _buildCircleButton(
      icon: Icons.play_arrow_rounded,
      tooltip: 'Play All',
      onPressed: _tracks.isEmpty
          ? null
          : () {
              ref.read(playbackProvider.notifier).playTrackList(_tracks);
            },
    );
  }

  Widget _buildDownloadAllCenterButton(BuildContext context) {
    return FilledButton.icon(
      onPressed: _tracks.isEmpty ? null : () => _confirmDownloadAll(context),
      icon: const Icon(Icons.download_rounded, size: 18),
      label: Text(context.l10n.downloadAllCount(_tracks.length)),
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
    );
  }

  Widget _buildShufflePlayButton() {
    return _buildCircleButton(
      icon: Icons.shuffle_rounded,
      tooltip: 'Shuffle Play',
      onPressed: _tracks.isEmpty ? null : _shufflePlayLocal,
    );
  }

  void _shufflePlayLocal() {
    if (_tracks.isEmpty) return;
    final shuffled = [..._tracks]..shuffle();
    final messenger = ScaffoldMessenger.of(context);
    ref.read(playbackProvider.notifier).playTrackList(shuffled).catchError((e) {
      if (!mounted) return;
      messenger.showSnackBar(
        SnackBar(content: Text('Cannot shuffle play local tracks: $e')),
      );
    });
  }

  void _confirmDownloadAll(BuildContext context) {
    if (_tracks.isEmpty) return;
    showDialog(
      context: context,
      builder: (dialogContext) {
        final colorScheme = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surfaceContainerHigh,
          title: const Text('Download All'),
          content: Text('Download ${_tracks.length} tracks?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(context.l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                _downloadAll(context);
              },
              child: const Text('Download'),
            ),
          ],
        );
      },
    );
  }

  void _downloadAll(BuildContext context) {
    _downloadTracks(context, _tracks);
  }

  void _downloadTracks(BuildContext context, List<Track> tracks) {
    if (tracks.isEmpty) return;
    final settings = ref.read(settingsProvider);
    if (settings.askQualityBeforeDownload) {
      DownloadServicePicker.show(
        context,
        trackName: '${tracks.length} tracks',
        artistName: widget.playlistName,
        onSelect: (quality, service) {
          ref
              .read(downloadQueueProvider.notifier)
              .addMultipleToQueue(tracks, service, qualityOverride: quality);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                context.l10n.snackbarAddedTracksToQueue(tracks.length),
              ),
            ),
          );
        },
      );
    } else {
      ref
          .read(downloadQueueProvider.notifier)
          .addMultipleToQueue(tracks, settings.defaultService);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.snackbarAddedTracksToQueue(tracks.length)),
        ),
      );
    }
  }
}

/// Separate Consumer widget for each track - only rebuilds when this specific track's status changes
class _PlaylistTrackItem extends ConsumerWidget {
  final Track track;
  final List<Track> tracksList;
  final VoidCallback onDownload;

  const _PlaylistTrackItem({
    required this.track,
    required this.tracksList,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    final queueItem = ref.watch(
      downloadQueueLookupProvider.select(
        (lookup) => lookup.byTrackId[track.id],
      ),
    );

    final isInHistory = ref.watch(
      downloadHistoryProvider.select((state) {
        return state.isDownloaded(track.id);
      }),
    );

    // Check local library for duplicate detection
    final showLocalLibraryIndicator = ref.watch(
      settingsProvider.select(
        (s) => s.localLibraryEnabled && s.localLibraryShowDuplicates,
      ),
    );
    final isInLocalLibrary = showLocalLibraryIndicator
        ? ref.watch(
            localLibraryProvider.select(
              (state) => state.existsInLibrary(
                isrc: track.isrc,
                trackName: track.name,
                artistName: track.artistName,
              ),
            ),
          )
        : false;

    final isQueued = queueItem != null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          leading: track.coverUrl != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: track.coverUrl!,
                    width: 48,
                    height: 48,
                    fit: BoxFit.cover,
                    memCacheWidth: 96,
                    cacheManager: CoverCacheManager.instance,
                  ),
                )
              : Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.music_note,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
          title: Text(
            track.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle: Row(
            children: [
              Flexible(
                child: Text(
                  track.artistName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: colorScheme.onSurfaceVariant),
                ),
              ),
              if (isInLocalLibrary) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.folder_outlined,
                        size: 10,
                        color: colorScheme.onTertiaryContainer,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        context.l10n.libraryInLibrary,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onTertiaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
          trailing: TrackCollectionQuickActions(track: track),
          onTap: () => _handleTap(
            context,
            ref,
            isQueued: isQueued,
            isInHistory: isInHistory,
            isInLocalLibrary: isInLocalLibrary,
          ),
          onLongPress: () => TrackCollectionQuickActions.showTrackOptionsSheet(
            context,
            ref,
            track,
          ),
        ),
      ),
    );
  }

  void _handleTap(
    BuildContext context,
    WidgetRef ref, {
    required bool isQueued,
    required bool isInHistory,
    required bool isInLocalLibrary,
  }) async {
    if (isQueued) return;

    if (isInLocalLibrary) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.snackbarAlreadyInLibrary(track.name)),
          ),
        );
      }
      return;
    }

    final settings = ref.read(settingsProvider);
    if (settings.interactionMode == 'stream') {
      if (tracksList.isNotEmpty) {
        final index = tracksList.indexWhere((t) => t.id == track.id);
        if (index != -1) {
          ref
              .read(playbackProvider.notifier)
              .playTrackList(tracksList, startIndex: index);
          return;
        }
      }

      // Fallback
      ref.read(playbackProvider.notifier).playTrackList([track], startIndex: 0);
      return;
    }

    if (isInHistory) {
      final historyItem = ref
          .read(downloadHistoryProvider.notifier)
          .getBySpotifyId(track.id);
      if (historyItem != null) {
        final exists = await fileExists(historyItem.filePath);
        if (exists) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  context.l10n.snackbarAlreadyDownloaded(track.name),
                ),
              ),
            );
          }
          return;
        } else {
          ref
              .read(downloadHistoryProvider.notifier)
              .removeBySpotifyId(track.id);
        }
      }
    }

    onDownload();
  }
}
