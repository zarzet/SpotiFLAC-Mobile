import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/recent_access_provider.dart';
import 'package:spotiflac_android/providers/local_library_provider.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/file_access.dart';
import 'package:spotiflac_android/widgets/download_service_picker.dart';
import 'package:spotiflac_android/screens/artist_screen.dart';
import 'package:spotiflac_android/screens/home_tab.dart' show ExtensionArtistScreen;

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

class AlbumScreen extends ConsumerStatefulWidget {
  final String albumId;
  final String albumName;
  final String? coverUrl;
  final List<Track>? tracks;
  final String? extensionId;
  final String? artistId;
  final String? artistName;

  const AlbumScreen({
    super.key,
    required this.albumId,
    required this.albumName,
    this.coverUrl,
    this.tracks,
    this.extensionId,
    this.artistId,
    this.artistName,
  });

  @override
  ConsumerState<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends ConsumerState<AlbumScreen> {
  List<Track>? _tracks;
  bool _isLoading = false;
  String? _error;
  bool _showTitleInAppBar = false;
  String? _artistId;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Use extensionId if available, otherwise detect from albumId prefix
      final providerId = widget.extensionId ?? 
          (widget.albumId.startsWith('deezer:') ? 'deezer' : 'spotify');
      ref.read(recentAccessProvider.notifier).recordAlbumAccess(
        id: widget.albumId,
        name: widget.albumName,
        artistName: widget.tracks?.firstOrNull?.artistName,
        imageUrl: widget.coverUrl,
        providerId: providerId,
);
    });
    
    if (widget.tracks != null && widget.tracks!.isNotEmpty) {
      _tracks = widget.tracks;
    } else {
      _tracks = _AlbumCache.get(widget.albumId);
    }
    _artistId = widget.artistId;
    
    if (_tracks == null || _tracks!.isEmpty) {
      _fetchTracks();
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    final shouldShow = _scrollController.offset > 280;
    if (shouldShow != _showTitleInAppBar) {
      setState(() => _showTitleInAppBar = shouldShow);
    }
  }

  String _formatReleaseDate(String date) {
    if (date.length >= 10) {
      final parts = date.substring(0, 10).split('-');
      if (parts.length == 3) {
        return '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    } else if (date.length >= 7) {
      final parts = date.split('-');
      if (parts.length >= 2) {
        return '${parts[1]}/${parts[0]}';
      }
    }
    return date;
  }

Future<void> _fetchTracks() async {
    setState(() => _isLoading = true);
    try {
      Map<String, dynamic> metadata;
      
      if (widget.albumId.startsWith('deezer:')) {
        final deezerAlbumId = widget.albumId.replaceFirst('deezer:', '');
        metadata = await PlatformBridge.getDeezerMetadata('album', deezerAlbumId);
      } else {
        final url = 'https://open.spotify.com/album/${widget.albumId}';
        metadata = await PlatformBridge.getSpotifyMetadataWithFallback(url);
      }
      
      final trackList = metadata['track_list'] as List<dynamic>;
      final tracks = trackList.map((t) => _parseTrack(t as Map<String, dynamic>)).toList();
      
      final albumInfo = metadata['album_info'] as Map<String, dynamic>?;
      final artistId = albumInfo?['artist_id'] as String?;
      
      _AlbumCache.set(widget.albumId, tracks);
      
      if (mounted) {
        setState(() {
          _tracks = tracks;
          _artistId = artistId;
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
        controller: _scrollController,
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
    final screenWidth = MediaQuery.of(context).size.width;
    final coverSize = screenWidth * 0.5;
    
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showTitleInAppBar ? 1.0 : 0.0,
        child: Text(
          widget.albumName,
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
          final collapseRatio = (constraints.maxHeight - kToolbarHeight) / (320 - kToolbarHeight);
          final showContent = collapseRatio > 0.3;
          
          return FlexibleSpaceBar(
            collapseMode: CollapseMode.none,
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Blurred cover background
                if (widget.coverUrl != null)
                  CachedNetworkImage(
                    imageUrl: widget.coverUrl!,
                    fit: BoxFit.cover,
                    cacheManager: CoverCacheManager.instance,
                    placeholder: (_, _) => Container(color: colorScheme.surface),
                    errorWidget: (_, _, _) => Container(color: colorScheme.surface),
                  )
                else
                  Container(color: colorScheme.surface),
                ClipRect(
                  child: BackdropFilter(
                    filter: ImageFilter.blur(sigmaX: 30, sigmaY: 30),
                    child: Container(color: colorScheme.surface.withValues(alpha: 0.4)),
                  ),
                ),
                Positioned(
                  left: 0, right: 0, bottom: 0, height: 80,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [colorScheme.surface.withValues(alpha: 0.0), colorScheme.surface],
                      ),
                    ),
                  ),
                ),
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 150),
                  opacity: showContent ? 1.0 : 0.0,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 60),
                      child: Container(
                        width: coverSize,
                        height: coverSize,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 15),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(20),
                          child: widget.coverUrl != null
? CachedNetworkImage(
                                  imageUrl: widget.coverUrl!, 
                                  fit: BoxFit.cover, 
                                  memCacheWidth: (coverSize * 2).toInt(),
                                  cacheManager: CoverCacheManager.instance,
                                )
                              : Container(
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.album, size: 64, color: colorScheme.onSurfaceVariant),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
          );
        },
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.8), 
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

Widget _buildInfoCard(BuildContext context, ColorScheme colorScheme) {
    final tracks = _tracks ?? [];
    final artistName = tracks.isNotEmpty ? tracks.first.artistName : null;
    final releaseDate = tracks.isNotEmpty ? tracks.first.releaseDate : null;
    
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
                if (artistName != null && artistName.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () => _navigateToArtist(context, artistName),
                    child: Text(
                      artistName,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: colorScheme.primary,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                if (tracks.isNotEmpty)
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
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
                      if (releaseDate != null && releaseDate.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(color: colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(20)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.calendar_today, size: 14, color: colorScheme.onTertiaryContainer),
                              const SizedBox(width: 4),
                              Text(_formatReleaseDate(releaseDate), style: TextStyle(color: colorScheme.onTertiaryContainer, fontWeight: FontWeight.w600, fontSize: 12)),
                            ],
                          ),
                        ),
                    ],
                  ),
                if (tracks.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: () => _downloadAll(context),
                    icon: const Icon(Icons.download, size: 18),
                    label: Text(context.l10n.downloadAllCount(tracks.length)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
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

  void _navigateToArtist(BuildContext context, String artistName) {
    final artistId = _artistId ?? 
        (widget.albumId.startsWith('deezer:') ? 'deezer:unknown' : 'unknown');
    
    if (artistId == 'unknown' || artistId == 'deezer:unknown' || artistId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Artist information not available')),
      );
      return;
    }
    
    if (widget.extensionId != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ExtensionArtistScreen(
            extensionId: widget.extensionId!,
            artistId: artistId,
            artistName: artistName,
            coverUrl: widget.coverUrl,
          ),
        ),
      );
      return;
    }
    
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ArtistScreen(
          artistId: artistId,
          artistName: artistName,
          coverUrl: widget.coverUrl,
        ),
      ),
    );
  }

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

class _AlbumTrackItem extends ConsumerWidget {
  final Track track;
  final VoidCallback onDownload;

  const _AlbumTrackItem({required this.track, required this.onDownload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final queueItem = ref.watch(
      downloadQueueLookupProvider.select((lookup) => lookup.byTrackId[track.id]),
    );
    
    final isInHistory = ref.watch(downloadHistoryProvider.select((state) {
      return state.isDownloaded(track.id);
    }));
    
    final settings = ref.watch(settingsProvider);
    final showLocalLibraryIndicator = settings.localLibraryEnabled && settings.localLibraryShowDuplicates;
    final isInLocalLibrary = showLocalLibraryIndicator 
        ? ref.watch(localLibraryProvider.select((state) => 
            state.existsInLibrary(
              isrc: track.isrc,
              trackName: track.name,
              artistName: track.artistName,
            )))
        : false;
    
    final isQueued = queueItem != null;
    final isDownloading = queueItem?.status == DownloadStatus.downloading;
    final isFinalizing = queueItem?.status == DownloadStatus.finalizing;
    final isCompleted = queueItem?.status == DownloadStatus.completed;
    final progress = queueItem?.progress ?? 0.0;
    
    final showAsDownloaded = isCompleted || (!isQueued && isInHistory) || isInLocalLibrary;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 0,
        color: Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 2),
child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          leading: SizedBox(
            width: 32,
            child: Center(
              child: Text(
                '${track.trackNumber ?? 0}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
          subtitle: Row(
            children: [
              Flexible(child: Text(track.artistName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colorScheme.onSurfaceVariant))),
              if (isInLocalLibrary) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: colorScheme.tertiaryContainer,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.folder_outlined, size: 10, color: colorScheme.onTertiaryContainer),
                      const SizedBox(width: 3),
                      Text(context.l10n.libraryInLibrary, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w500, color: colorScheme.onTertiaryContainer)),
                    ],
                  ),
                ),
              ],
            ],
          ),
          trailing: _buildDownloadButton(context, ref, colorScheme, isQueued: isQueued, isDownloading: isDownloading, isFinalizing: isFinalizing, showAsDownloaded: showAsDownloaded, isInHistory: isInHistory, isInLocalLibrary: isInLocalLibrary, progress: progress),
          onTap: () => _handleTap(context, ref, isQueued: isQueued, isInHistory: isInHistory, isInLocalLibrary: isInLocalLibrary),
        ),
      ),
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, {required bool isQueued, required bool isInHistory, required bool isInLocalLibrary}) async {
    if (isQueued) return;
    
    if (isInLocalLibrary) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.snackbarAlreadyInLibrary(track.name))));
      }
      return;
    }
    
    if (isInHistory) {
      final historyItem = ref.read(downloadHistoryProvider.notifier).getBySpotifyId(track.id);
      if (historyItem != null) {
        final exists = await fileExists(historyItem.filePath);
        if (exists) {
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
    required bool isInLocalLibrary,
    required double progress,
  }) {
    const double size = 44.0;
    const double iconSize = 20.0;
    
    if (showAsDownloaded) {
      return GestureDetector(
        onTap: () => _handleTap(context, ref, isQueued: isQueued, isInHistory: isInHistory, isInLocalLibrary: isInLocalLibrary),
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
