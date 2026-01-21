import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/services/palette_service.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/widgets/download_service_picker.dart';

class PlaylistScreen extends ConsumerStatefulWidget {
  final String playlistName;
  final String? coverUrl;
  final List<Track> tracks;

  const PlaylistScreen({
    super.key,
    required this.playlistName,
    this.coverUrl,
    required this.tracks,
  });

  @override
  ConsumerState<PlaylistScreen> createState() => _PlaylistScreenState();
}

class _PlaylistScreenState extends ConsumerState<PlaylistScreen> {
  Color? _dominantColor;
  bool _showTitleInAppBar = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _extractDominantColor();
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

  Future<void> _extractDominantColor() async {
    if (widget.coverUrl == null) return;
    final color = await PaletteService.instance.extractDominantColor(widget.coverUrl);
    if (mounted && color != null) {
      setState(() => _dominantColor = color);
    }
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
          _buildTrackListHeader(context, colorScheme),
          _buildTrackList(context, colorScheme),
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    final screenWidth = MediaQuery.of(context).size.width;
    final coverSize = screenWidth * 0.5; // 50% of screen width
    final bgColor = _dominantColor ?? colorScheme.surface;
    
    return SliverAppBar(
      expandedHeight: 320,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface, // Use theme color for collapsed state
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
          final collapseRatio = (constraints.maxHeight - kToolbarHeight) / (320 - kToolbarHeight);
          final showContent = collapseRatio > 0.3;
          
          return FlexibleSpaceBar(
            collapseMode: CollapseMode.none,
            background: Stack(
              fit: StackFit.expand,
              children: [
                // Background with dominant color
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        bgColor,
                        bgColor.withValues(alpha: 0.8),
                        colorScheme.surface,
                      ],
                      stops: const [0.0, 0.6, 1.0],
                    ),
                  ),
                ),
                // Cover image centered - fade out when collapsing
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
                                  child: Icon(Icons.playlist_play, size: 64, color: colorScheme.onSurfaceVariant),
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
                Text(widget.playlistName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: colorScheme.tertiaryContainer, borderRadius: BorderRadius.circular(20)),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.playlist_play, size: 14, color: colorScheme.onTertiaryContainer),
                      const SizedBox(width: 4),
                      Text(context.l10n.tracksCount(widget.tracks.length), style: TextStyle(color: colorScheme.onTertiaryContainer, fontWeight: FontWeight.w600, fontSize: 12)),
                    ],
                  ),
                ),
const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: () => _downloadAll(context),
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(context.l10n.downloadAllCount(widget.tracks.length)),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  ),
                ),
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

  Widget _buildTrackList(BuildContext context, ColorScheme colorScheme) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = widget.tracks[index];
          return KeyedSubtree(
            key: ValueKey(track.id),
            child: _PlaylistTrackItem(
              track: track,
              onDownload: () => _downloadTrack(context, track),
            ),
          );
        },
        childCount: widget.tracks.length,
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
    if (widget.tracks.isEmpty) return;
    final settings = ref.read(settingsProvider);
    if (settings.askQualityBeforeDownload) {
      DownloadServicePicker.show(
        context,
        trackName: '${widget.tracks.length} tracks',
        artistName: widget.playlistName,
        onSelect: (quality, service) {
          ref.read(downloadQueueProvider.notifier).addMultipleToQueue(widget.tracks, service, qualityOverride: quality);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.snackbarAddedTracksToQueue(widget.tracks.length))));
        },
      );
    } else {
      ref.read(downloadQueueProvider.notifier).addMultipleToQueue(widget.tracks, settings.defaultService);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.l10n.snackbarAddedTracksToQueue(widget.tracks.length))));
    }
  }
}

/// Separate Consumer widget for each track - only rebuilds when this specific track's status changes
class _PlaylistTrackItem extends ConsumerWidget {
  final Track track;
  final VoidCallback onDownload;

  const _PlaylistTrackItem({required this.track, required this.onDownload});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    final queueItem = ref.watch(
      downloadQueueLookupProvider.select((lookup) => lookup.byTrackId[track.id]),
    );
    
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
              ? ClipRRect(borderRadius: BorderRadius.circular(8), child: CachedNetworkImage(imageUrl: track.coverUrl!, width: 48, height: 48, fit: BoxFit.cover, memCacheWidth: 96, cacheManager: CoverCacheManager.instance))
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
