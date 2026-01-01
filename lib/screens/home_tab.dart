import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';
import 'package:spotiflac_android/providers/track_provider.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/screens/track_metadata_screen.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});

  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> with AutomaticKeepAliveClientMixin {
  final _urlController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _urlController.text = data!.text!;
    }
  }

  Future<void> _fetchMetadata() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;

    if (url.startsWith('http') || url.startsWith('spotify:')) {
      await ref.read(trackProvider.notifier).fetchFromUrl(url);
    } else {
      await ref.read(trackProvider.notifier).search(url);
    }
  }

  void _downloadTrack(int index) {
    final trackState = ref.read(trackProvider);
    if (index >= 0 && index < trackState.tracks.length) {
      final track = trackState.tracks[index];
      final settings = ref.read(settingsProvider);
      ref.read(downloadQueueProvider.notifier).addToQueue(track, settings.defaultService);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Added "${track.name}" to queue')),
      );
    }
  }

  void _downloadAll() {
    final trackState = ref.read(trackProvider);
    if (trackState.tracks.isEmpty) return;
    
    final settings = ref.read(settingsProvider);
    ref.read(downloadQueueProvider.notifier).addMultipleToQueue(
      trackState.tracks,
      settings.defaultService,
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added ${trackState.tracks.length} tracks to queue')),
    );
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

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final trackState = ref.watch(trackProvider);
    final historyState = ref.watch(downloadHistoryProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return CustomScrollView(
      slivers: [
        // Search bar
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: TextField(
              controller: _urlController,
              decoration: InputDecoration(
                hintText: 'Paste Spotify URL or search...',
                prefixIcon: const Icon(Icons.link),
                suffixIcon: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(icon: const Icon(Icons.paste), onPressed: _pasteFromClipboard),
                    IconButton(icon: const Icon(Icons.search), onPressed: _fetchMetadata),
                  ],
                ),
              ),
              onSubmitted: (_) => _fetchMetadata(),
            ),
          ),
        ),

        // Error message
        if (trackState.error != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                trackState.error!, 
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          ),

        // Loading indicator
        if (trackState.isLoading)
          const SliverToBoxAdapter(
            child: LinearProgressIndicator(),
          ),

        // Album/Playlist header
        if (trackState.albumName != null || trackState.playlistName != null)
          SliverToBoxAdapter(child: _buildHeader(trackState, colorScheme)),

        // Download All button (when no header)
        if (trackState.tracks.length > 1 && trackState.albumName == null && trackState.playlistName == null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: FilledButton.icon(
                onPressed: _downloadAll,
                icon: const Icon(Icons.download),
                label: Text('Download All (${trackState.tracks.length})'),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
          ),

        // Track list
        if (trackState.tracks.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildTrackTile(index, colorScheme),
              childCount: trackState.tracks.length,
            ),
          ),

        // Divider between search results and history
        if (trackState.tracks.isNotEmpty && historyState.items.isNotEmpty)
          const SliverToBoxAdapter(
            child: Divider(height: 32),
          ),

        // Recent Downloads section header
        if (historyState.items.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Downloads',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () => _showClearHistoryDialog(colorScheme),
                    child: const Text('Clear'),
                  ),
                ],
              ),
            ),
          ),

        // Recent Downloads list
        if (historyState.items.isNotEmpty)
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => _buildHistoryTile(historyState.items[index], colorScheme),
              childCount: historyState.items.length > 5 ? 5 : historyState.items.length,
            ),
          ),

        // Show more history button
        if (historyState.items.length > 5)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: OutlinedButton(
                onPressed: () => _showAllHistory(colorScheme),
                child: Text('Show all ${historyState.items.length} downloads'),
              ),
            ),
          ),

        // Empty state (when no tracks and no history)
        if (trackState.tracks.isEmpty && historyState.items.isEmpty)
          SliverFillRemaining(
            child: _buildEmptyState(colorScheme),
          ),

        // Bottom padding
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }

  Widget _buildHeader(TrackState state, ColorScheme colorScheme) {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (state.coverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: state.coverUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    width: 80,
                    height: 80,
                    color: colorScheme.surfaceContainerHighest,
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.albumName ?? state.playlistName ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${state.tracks.length} tracks',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            // Download all button
            FilledButton.tonal(
              onPressed: _downloadAll,
              style: FilledButton.styleFrom(
                shape: const CircleBorder(),
                padding: const EdgeInsets.all(16),
              ),
              child: const Icon(Icons.download),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackTile(int index, ColorScheme colorScheme) {
    final track = ref.watch(trackProvider).tracks[index];
    return ListTile(
      leading: track.coverUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: track.coverUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
              ),
            )
          : Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
            ),
      title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        track.artistName, 
        maxLines: 1, 
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: IconButton(
        icon: Icon(Icons.download, color: colorScheme.primary),
        onPressed: () => _downloadTrack(index),
      ),
      onTap: () => _downloadTrack(index),
    );
  }

  Widget _buildHistoryTile(DownloadHistoryItem item, ColorScheme colorScheme) {
    final fileExists = File(item.filePath).existsSync();
    
    return ListTile(
      leading: Hero(
        tag: 'cover_${item.id}',
        child: item.coverUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: item.coverUrl!,
                  width: 48,
                  height: 48,
                  fit: BoxFit.cover,
                ),
              )
            : Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
              ),
      ),
      title: Text(item.trackName, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(
        item.artistName,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(color: colorScheme.onSurfaceVariant),
      ),
      trailing: fileExists
          ? IconButton(
              icon: Icon(Icons.play_arrow, color: colorScheme.primary),
              onPressed: () => _openFile(item.filePath),
            )
          : Icon(Icons.error_outline, color: colorScheme.error, size: 20),
      // Tap to show metadata details
      onTap: () => _navigateToMetadataScreen(item),
    );
  }

  void _navigateToMetadataScreen(DownloadHistoryItem item) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) => 
            TrackMetadataScreen(item: item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: animation,
            child: child,
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.music_note, 
            size: 64, 
            color: colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'Paste a Spotify URL to get started',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  void _showClearHistoryDialog(ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clear History'),
        content: const Text('Clear all download history?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadHistoryProvider.notifier).clearHistory();
              Navigator.pop(context);
            },
            child: Text('Clear', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }

  void _showAllHistory(ColorScheme colorScheme) {
    final historyState = ref.read(downloadHistoryProvider);
    
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'All Downloads (${historyState.items.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                controller: scrollController,
                itemCount: historyState.items.length,
                itemBuilder: (context, index) {
                  final item = historyState.items[index];
                  final fileExists = File(item.filePath).existsSync();
                  
                  return ListTile(
                    leading: item.coverUrl != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: CachedNetworkImage(
                              imageUrl: item.coverUrl!,
                              width: 48,
                              height: 48,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
                          ),
                    title: Text(item.trackName, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      item.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: colorScheme.onSurfaceVariant),
                    ),
                    trailing: fileExists
                        ? IconButton(
                            icon: Icon(Icons.play_arrow, color: colorScheme.primary),
                            onPressed: () => _openFile(item.filePath),
                          )
                        : Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                    onTap: () {
                      Navigator.pop(context); // Close bottom sheet first
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _navigateToMetadataScreen(item);
                      });
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
