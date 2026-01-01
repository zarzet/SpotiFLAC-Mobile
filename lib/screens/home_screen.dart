import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/providers/track_provider.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final _urlController = TextEditingController();
  int _currentIndex = 0;

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

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    switch (index) {
      case 0:
        // Already on home
        break;
      case 1:
        context.push('/queue');
        break;
      case 2:
        context.push('/history');
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    final trackState = ref.watch(trackProvider);
    final queueState = ref.watch(downloadQueueProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: CircleAvatar(
            backgroundColor: colorScheme.primaryContainer,
            child: Icon(Icons.music_note, color: colorScheme.onPrimaryContainer, size: 20),
          ),
        ),
        title: const Text('SpotiFLAC'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // URL Input
          Padding(
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

          // Error message
          if (trackState.error != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                trackState.error!, 
                style: TextStyle(color: colorScheme.error),
              ),
            ),

          // Loading indicator
          if (trackState.isLoading)
            LinearProgressIndicator(color: colorScheme.primary),

          // Album/Playlist header
          if (trackState.albumName != null || trackState.playlistName != null)
            _buildHeader(trackState, colorScheme),

          // Download All button
          if (trackState.tracks.length > 1)
            Padding(
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

          // Track list
          Expanded(
            child: trackState.tracks.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
                    itemCount: trackState.tracks.length,
                    itemBuilder: (context, index) => _buildTrackTile(index, colorScheme),
                  ),
          ),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onNavTap,
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.search_outlined),
            selectedIcon: Icon(Icons.search),
            label: 'Search',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: queueState.queuedCount > 0,
              label: Text('${queueState.queuedCount}'),
              child: const Icon(Icons.queue_music_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: queueState.queuedCount > 0,
              label: Text('${queueState.queuedCount}'),
              child: const Icon(Icons.queue_music),
            ),
            label: 'Queue',
          ),
          const NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'History',
          ),
        ],
      ),
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
            // Play all button
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
      trailing: Text(
        _formatDuration(track.duration),
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          color: colorScheme.onSurfaceVariant,
        ),
      ),
      onTap: () => _downloadTrack(index),
    );
  }

  String _formatDuration(int ms) {
    if (ms == 0) return '';
    final duration = Duration(milliseconds: ms);
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
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
}
