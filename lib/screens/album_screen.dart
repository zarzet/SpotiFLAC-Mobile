import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/recent_access_provider.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/widgets/download_service_picker.dart';

/// Simple in-memory cache for album tracks
class _AlbumCache {
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _ttl = Duration(minutes: 10);

  static List<Track>? get(String albumId) {
    final entry = _cache[albumId];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(albumId);
      return null;
    }
    return entry.tracks;
  }

  static void set(String albumId, List<Track> tracks) {
    _cache[albumId] = _CacheEntry(tracks, DateTime.now().add(_ttl));
  }
}

class _CacheEntry {
  final List<Track> tracks;
  final DateTime expiresAt;
  _CacheEntry(this.tracks, this.expiresAt);
}

/// Album detail screen with Material Expressive 3 design
class AlbumScreen extends ConsumerStatefulWidget {
  final String albumId;
  final String albumName;
  final String? coverUrl;
  final List<Track>? tracks; // Optional - will fetch if null

  const AlbumScreen({
    super.key,
    required this.albumId,
    required this.albumName,
    this.coverUrl,
    this.tracks,
  });

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  List<Track>? _tracks;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final providerId = widget.albumId.startsWith('deezer:') ? 'deezer' : 'spotify';
      ref.read(recentAccessProvider.notifier).recordAlbumAccess(
        id: widget.albumId,
        name: widget.albumName,
        artistName: widget.tracks?.firstOrNull?.artistName,
        imageUrl: widget.coverUrl,
        providerId: providerId,
      );
    });
    
    _tracks = widget.tracks ?? _AlbumCache.get(widget.albumId);
    if (_tracks == null) {
      _fetchTracks();
    }
  }

  Future<void> _fetchTracks() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> metadata;
      
      if (widget.albumId.startsWith('deezer:')) {
        final deezerAlbumId = widget.albumId.replaceFirst('deezer:', '');
        // ignore: avoid_print
        print('[AlbumScreen] Fetching from Deezer: $deezerAlbumId');
        metadata = await PlatformBridge.getDeezerMetadata('album', deezerAlbumId);
      } else {
        // ignore: avoid_print
        print('[AlbumScreen] Fetching from Spotify with fallback: ${widget.albumId}');
        final url = 'https://open.spotify.com/album/${widget.albumId}';
        metadata = await PlatformBridge.getSpotifyMetadataWithFallback(url);
      }
      
      final trackList = metadata['track_list'] as List<dynamic>;
      final tracks = trackList.map((t) => _parseTrack(t as Map<String, dynamic>)).toList();
      
      _AlbumCache.set(widget.albumId, tracks);
      
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
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
      duration: ((data['duration_ms'] as int? ?? 0) / 1000).round(),
      trackNumber: data['track_number'] as int?,
      discNumber: data['disc_number'] as int?,
      releaseDate: data['release_date'] as String?,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final tracks = _tracks ?? [];

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildAppBar(context, colorScheme),
          _buildInfoCard(context, colorScheme),
          if (_isLoading)
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )),
            if (_error != null)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildErrorWidget(_error!, colorScheme),
            )),
          if (!_isLoading && _error == null && tracks.isNotEmpty) ...[
            _buildTrackListHeader(context, colorScheme),
            _buildTrackList(context, colorScheme, tracks),
          ],
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.coverUrl != null)
              CachedNetworkImage(
                imageUrl: widget.coverUrl!,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.5),
                colorBlendMode: BlendMode.darken,
                memCacheWidth: 600,
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    colorScheme.surface.withValues(alpha: 0.8),
                    colorScheme.surface,
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(16),
                    child: widget.coverUrl != null
                        ? CachedNetworkImage(imageUrl: widget.coverUrl!, fit: BoxFit.cover, memCacheWidth: 280)
                        : Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.album, size: 48, color: colorScheme.onSurfaceVariant),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: colorScheme.surface.withValues(alpha: 0.8), shape: BoxShape.circle),
          child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ColorScheme colorScheme) {
    final tracks = _tracks ?? [];
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.albumName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 8),
                if (tracks.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: colorScheme.secondaryContainer, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.music_note, size: 14, color: colorScheme.onSecondaryContainer),
                        const SizedBox(width: 4),
                        Text(context.l10n.tracksCount(tracks.length), style: TextStyle(color: colorScheme.onSecondaryContainer, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
                if (tracks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _downloadAll(context),
                    icon: const Icon(Icons.download),
                    label: Text(context.l10n.downloadAllCount(tracks.length)),
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTrackListHeader(BuildContext context, ColorScheme colorScheme) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            Icon(Icons.queue_music, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(context.l10n.tracksHeader, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList(BuildContext context, ColorScheme colorScheme, List<Track> tracks) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = tracks[index];
          return KeyedSubtree(
            key: ValueKey(track.id),
            child: _AlbumTrackItem(
              track: track,
              onDownload: () => _downloadTrack(context, track),
            ),
          );
        },
        childCount: tracks.length,
      ),
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
          ref.read(downloadQueueProvider.notifier).addToQueue(track, service, qualityOverride: quality);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.snackbarAddedToQueue(track.name))));
        },
      );
    } else {
      ref.read(downloadQueueProvider.notifier).addToQueue(track, settings.defaultService);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.snackbarAddedToQueue(track.name))));
    }
  }

  void _downloadAll(BuildContext context) {
    final tracks = _tracks;
    if (tracks == null || tracks.isEmpty) return;
    final settings = ref.read(settingsProvider);
    if (settings.askQualityBeforeDownload) {
      DownloadServicePicker.show(
        context,
        trackName: '${tracks.length} tracks',
        artistName: widget.albumName,
        onSelect: (quality, service) {
          ref.read(downloadQueueProvider.notifier).addMultipleToQueue(tracks, service, qualityOverride: quality);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.snackbarAddedTracksToQueue(tracks.length))));
        },
      );
    } else {
      ref.read(downloadQueueProvider.notifier).addMultipleToQueue(tracks, settings.defaultService);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.snackbarAddedTracksToQueue(tracks.length))));
    }
  }

  /// Build error widget with special handling for rate limit (429)
  Widget _buildErrorWidget(String error, ColorScheme colorScheme) {
    final isRateLimit = error.contains('429') || 
                        error.toLowerCase().contains('rate limit') ||
                        error.toLowerCase().contains('too many requests');
    
    if (isRateLimit) {
      return Card(
        elevation: 0,
        color: colorScheme.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.timer_off, color: colorScheme.onErrorContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.l10n.errorRateLimited,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      context.l10n.errorRateLimitedMessage,
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      elevation: 0,
      color: colorScheme.errorContainer.withValues(alpha: 0.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: colorScheme.error),
            const SizedBox(width: 12),
            Expanded(child: Text(error, style: TextStyle(color: colorScheme.error))),
          ],
        ),
      ),
    );
  }
}

/// Separate Consumer widget for each track - only rebuilds when this specific track's status changes
class _AlbumTrackItem extends ConsumerWidget {
  final Track track;
  final VoidCallback onDownload;

  const _AlbumTrackItem({required this.track, required this.onDownload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final queueItem = ref.watch(downloadQueueProvider.select((state) {
      return state.items.where((item) => item.track.id == track.id).firstOrNull;
    }));
    
    final isInHistory = ref.watch(downloadHistoryProvider.select((state) {
      return state.isDownloaded(track.id);
    }));
    
    final isQueued = queueItem != null;
    final isDownloading = queueItem?.status == DownloadStatus.downloading;
    final isFinalizing = queueItem?.status == DownloadStatus.finalizing;
    final isCompleted = queueItem?.status == DownloadStatus.completed;
    final progress = queueItem?.progress ?? 0.0;
    
    final showAsDownloaded = isCompleted || (!isQueued && isInHistory);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: track.coverUrl != null
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: track.coverUrl!, width: 48, height: 48, fit: BoxFit.cover, memCacheWidth: 96))
              : Container(width: 48, height: 48, decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)), child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant)),
          title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
          subtitle: Text(track.artistName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colorScheme.onSurfaceVariant)),
          trailing: _buildDownloadButton(context, ref, colorScheme, isQueued: isQueued, isDownloading: isDownloading, isFinalizing: isFinalizing, showAsDownloaded: showAsDownloaded, isInHistory: isInHistory, progress: progress),
          onTap: () => _handleTap(context, ref, isQueued: isQueued, isInHistory: isInHistory),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, {required bool isQueued, required bool isInHistory}) async {
    if (isQueued) return;
    
    if (isInHistory) {
      final historyItem = ref.read(downloadHistoryProvider.notifier).getBySpotifyId(track.id);
      if (historyItem != null) {
        final fileExists = await File(historyItem.filePath).exists();
        if (fileExists) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.snackbarAlreadyDownloaded(track.name))));
          }
          return;
        } else {
          ref.read(downloadHistoryProvider.notifier).removeBySpotifyId(track.id);
        }
      }
    }
    
    onDownload();
  }

  Widget _buildDownloadButton(BuildContext context, WidgetRef ref, ColorScheme colorScheme, {
    required bool isQueued,
    required bool isDownloading,
    required bool isFinalizing,
    required bool showAsDownloaded,
    required bool isInHistory,
    required double progress,
  }) {
    const double size = 44.0;
    const double iconSize = 20.0;
    
    if (showAsDownloaded) {
      return GestureDetector(
        onTap: () => _handleTap(context, ref, isQueued: isQueued, isInHistory: isInHistory),
        child: Container(width: size, height: size, decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle), child: Icon(Icons.check, color: colorScheme.onPrimaryContainer, size: iconSize)),
      );
    } else if (isFinalizing) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(strokeWidth: 3, color: colorScheme.tertiary, backgroundColor: colorScheme.surfaceContainerHighest),
            Icon(Icons.edit_note, color: colorScheme.tertiary, size: 16),
          ],
        ),
      );
    } else if (isDownloading) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(value: progress > 0 ? progress : null, strokeWidth: 3, color: colorScheme.primary, backgroundColor: colorScheme.surfaceContainerHighest),
            if (progress > 0) Text('${(progress * 100).toInt()}', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: colorScheme.primary)),
          ],
        ),
      );
    } else if (isQueued) {
      return Container(width: size, height: size, decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, shape: BoxShape.circle), child: Icon(Icons.hourglass_empty, color: colorScheme.onSurfaceVariant, size: iconSize));
    } else {
      return GestureDetector(
        onTap: onDownload,
        child: Container(width: size, height: size, decoration: BoxDecoration(color: colorScheme.secondaryContainer, shape: BoxShape.circle), child: Icon(Icons.download, color: colorScheme.onSecondaryContainer, size: iconSize)),
      );
    }
  }
}
