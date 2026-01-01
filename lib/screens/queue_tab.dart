import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/screens/track_metadata_screen.dart';

class QueueTab extends ConsumerStatefulWidget {
  const QueueTab({super.key});
  @override
  ConsumerState<QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends ConsumerState<QueueTab> {
  final Map<String, bool> _fileExistsCache = {};

  bool _checkFileExists(String? filePath) {
    if (filePath == null) return false;
    if (_fileExistsCache.containsKey(filePath)) {
      return _fileExistsCache[filePath]!;
    }
    Future.microtask(() async {
      final exists = await File(filePath).exists();
      if (mounted && _fileExistsCache[filePath] != exists) {
        setState(() => _fileExistsCache[filePath] = exists);
      }
    });
    _fileExistsCache[filePath] = false;
    return false;
  }

  Future<void> _openFile(String filePath) async {
    try {
      await OpenFilex.open(filePath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open file: $e')),
        );
      }
    }
  }

  void _navigateToMetadataScreen(DownloadItem item) {
    final historyItem = ref.read(downloadHistoryProvider).items.firstWhere(
      (h) => h.filePath == item.filePath,
      orElse: () => DownloadHistoryItem(
        id: item.id,
        trackName: item.track.name,
        artistName: item.track.artistName,
        albumName: item.track.albumName,
        coverUrl: item.track.coverUrl,
        filePath: item.filePath ?? '',
        downloadedAt: DateTime.now(),
        service: item.service,
      ),
    );
    
    Navigator.push(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => TrackMetadataScreen(item: historyItem),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final queueState = ref.watch(downloadQueueProvider);
    final historyState = ref.watch(downloadHistoryProvider);
    final historyViewMode = ref.watch(settingsProvider.select((s) => s.historyViewMode));
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Collapsing App Bar - Simplified for performance
        SliverAppBar(
          expandedHeight: 100,
          collapsedHeight: kToolbarHeight,
          floating: false,
          pinned: true,
          backgroundColor: colorScheme.surface,
          surfaceTintColor: Colors.transparent,
          automaticallyImplyLeading: false,
          flexibleSpace: FlexibleSpaceBar(
            expandedTitleScale: 1.4,
            titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
            title: Text(
              'History',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
        ),

        // Pause/Resume controls - only show when multiple items or paused
        if ((queueState.isProcessing || queueState.queuedCount > 0) && (queueState.items.length > 1 || queueState.isPaused))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      // Status icon
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: queueState.isPaused 
                              ? colorScheme.errorContainer 
                              : colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          queueState.isPaused ? Icons.pause : Icons.downloading,
                          color: queueState.isPaused 
                              ? colorScheme.onErrorContainer 
                              : colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Status text - simplified
                      Expanded(
                        child: Text(
                          queueState.isPaused 
                              ? 'Paused' 
                              : '${queueState.completedCount}/${queueState.items.length}',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      // Pause/Resume button
                      FilledButton.tonal(
                        onPressed: () => ref.read(downloadQueueProvider.notifier).togglePause(),
                        child: Text(queueState.isPaused ? 'Resume' : 'Pause'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

        // Queue header
        if (queueState.items.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('Downloading (${queueState.items.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),

        // Queue list
        if (queueState.items.isNotEmpty)
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, index) => _buildQueueItem(context, queueState.items[index], colorScheme),
            childCount: queueState.items.length,
          )),

        // History section header - show count only
        if (historyState.items.isNotEmpty && queueState.items.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text('${historyState.items.length} ${historyState.items.length == 1 ? 'track' : 'tracks'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            ),
          ),

        // History section header when queue has items (show "Downloaded" label)
        if (historyState.items.isNotEmpty && queueState.items.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text('Downloaded',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ),
          ),

        // History - Grid or List based on setting
        if (historyState.items.isNotEmpty)
          historyViewMode == 'grid'
              ? SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      mainAxisSpacing: 8,
                      crossAxisSpacing: 8,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildHistoryGridItem(context, historyState.items[index], colorScheme),
                      childCount: historyState.items.length,
                    ),
                  ),
                )
              : SliverList(delegate: SliverChildBuilderDelegate(
                  (context, index) => _buildHistoryItem(context, historyState.items[index], colorScheme),
                  childCount: historyState.items.length,
                )),

        // Empty state when both queue and history are empty
        if (queueState.items.isEmpty && historyState.items.isEmpty)
          SliverFillRemaining(hasScrollBody: false, child: _buildEmptyState(context, colorScheme))
        else
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context, ColorScheme colorScheme) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Icon(Icons.history, size: 64, color: colorScheme.onSurfaceVariant),
      const SizedBox(height: 16),
      Text('No download history', style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant)),
      const SizedBox(height: 8),
      Text('Downloaded tracks will appear here', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7))),
    ]),
  );

  Widget _buildQueueItem(BuildContext context, DownloadItem item, ColorScheme colorScheme) {
    final isCompleted = item.status == DownloadStatus.completed;
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: isCompleted ? () => _navigateToMetadataScreen(item) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover art with Hero for completed items
              isCompleted
                  ? Hero(
                      tag: 'cover_${item.id}',
                      child: _buildCoverArt(item, colorScheme),
                    )
                  : _buildCoverArt(item, colorScheme),
              const SizedBox(width: 12),
              
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.track.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.status == DownloadStatus.downloading) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.progress > 0 ? item.progress : null,
                                backgroundColor: colorScheme.surfaceContainerHighest,
                                color: colorScheme.primary,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${(item.progress * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (item.status == DownloadStatus.failed) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.error ?? 'Download failed',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Action buttons based on status
              _buildActionButtons(context, item, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverArt(DownloadItem item, ColorScheme colorScheme) {
    return item.track.coverUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.track.coverUrl!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              memCacheWidth: 112,
              memCacheHeight: 112,
            ),
          )
        : Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
          );
  }

  Widget _buildActionButtons(BuildContext context, DownloadItem item, ColorScheme colorScheme) {
    switch (item.status) {
      case DownloadStatus.queued:
        // Queued: Show cancel button
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => ref.read(downloadQueueProvider.notifier).cancelItem(item.id),
              icon: Icon(Icons.close, color: colorScheme.error),
              tooltip: 'Cancel',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
        
      case DownloadStatus.downloading:
        // Downloading: Show stop button
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => ref.read(downloadQueueProvider.notifier).cancelItem(item.id),
              icon: Icon(Icons.stop, color: colorScheme.error),
              tooltip: 'Stop',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
        
      case DownloadStatus.completed:
        // Completed: Show play button and check icon
        final fileExists = _checkFileExists(item.filePath);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fileExists)
              IconButton(
                onPressed: () => _openFile(item.filePath!),
                icon: Icon(Icons.play_arrow, color: colorScheme.primary),
                tooltip: 'Play',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                ),
              )
            else
              Icon(Icons.error_outline, color: colorScheme.error, size: 20),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.check, color: colorScheme.onPrimaryContainer, size: 20),
            ),
          ],
        );
        
      case DownloadStatus.failed:
        // Failed: Show retry and remove buttons
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => ref.read(downloadQueueProvider.notifier).retryItem(item.id),
              icon: Icon(Icons.refresh, color: colorScheme.primary),
              tooltip: 'Retry',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => ref.read(downloadQueueProvider.notifier).removeItem(item.id),
              icon: Icon(Icons.close, color: colorScheme.error),
              tooltip: 'Remove',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
              ),
            ),
          ],
        );
        
      case DownloadStatus.skipped:
        // Skipped: Show retry and remove buttons
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => ref.read(downloadQueueProvider.notifier).retryItem(item.id),
              icon: Icon(Icons.refresh, color: colorScheme.primary),
              tooltip: 'Retry',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () => ref.read(downloadQueueProvider.notifier).removeItem(item.id),
              icon: Icon(Icons.close, color: colorScheme.onSurfaceVariant),
              tooltip: 'Remove',
            ),
          ],
        );
    }
  }

  void _navigateToHistoryMetadataScreen(DownloadHistoryItem item) {
    Navigator.push(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => TrackMetadataScreen(item: item),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  Widget _buildHistoryGridItem(BuildContext context, DownloadHistoryItem item, ColorScheme colorScheme) {
    final fileExists = _checkFileExists(item.filePath);
    
    return GestureDetector(
      onTap: () => _navigateToHistoryMetadataScreen(item),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cover art with play button overlay
          Stack(
            children: [
              AspectRatio(
                aspectRatio: 1,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: item.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.coverUrl!,
                          fit: BoxFit.cover,
                          memCacheWidth: 200,
                          memCacheHeight: 200,
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant, size: 32),
                        ),
                ),
              ),
              // Play button overlay
              if (fileExists)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: GestureDetector(
                    onTap: () => _openFile(item.filePath),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.play_arrow, color: colorScheme.onPrimary, size: 16),
                    ),
                  ),
                ),
              // Error indicator if file missing
              if (!fileExists)
                Positioned(
                  right: 4,
                  bottom: 4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: colorScheme.errorContainer,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.error_outline, color: colorScheme.error, size: 14),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          // Track name
          Text(
            item.trackName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
            ),
          ),
          // Artist name
          Text(
            item.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(BuildContext context, DownloadHistoryItem item, ColorScheme colorScheme) {
    final fileExists = _checkFileExists(item.filePath);
    final date = item.downloadedAt;
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final dateStr = '${months[date.month - 1]} ${date.day}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: () => _navigateToHistoryMetadataScreen(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Cover art
              item.coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.coverUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        memCacheWidth: 112,
                        memCacheHeight: 112,
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
                    ),
              const SizedBox(width: 12),
              
              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.trackName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      dateStr,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Action buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (fileExists)
                    IconButton(
                      onPressed: () => _openFile(item.filePath),
                      icon: Icon(Icons.play_arrow, color: colorScheme.primary),
                      tooltip: 'Play',
                      style: IconButton.styleFrom(
                        backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
                      ),
                    )
                  else
                    Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
