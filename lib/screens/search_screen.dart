import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/track_provider.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/playback_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';

class SearchScreen extends ConsumerStatefulWidget {
  final String query;

  const SearchScreen({super.key, required this.query});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.query);
    if (widget.query.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final settings = ref.read(settingsProvider);
        ref
            .read(trackProvider.notifier)
            .search(widget.query, metadataSource: settings.metadataSource);
      });
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search() {
    final query = _searchController.text.trim();
    if (query.isNotEmpty) {
      final settings = ref.read(settingsProvider);
      ref
          .read(trackProvider.notifier)
          .search(query, metadataSource: settings.metadataSource);
    }
  }

  void _downloadTrack(Track track) {
    final settings = ref.read(settingsProvider);
    ref
        .read(downloadQueueProvider.notifier)
        .addToQueue(track, settings.defaultService);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Added "${track.name}" to queue')));
  }

  Future<void> _playTrack(Track track) async {
    try {
      // Play the track and set the entire search result as the queue
      final tracks = ref.read(trackProvider).tracks;
      await ref
          .read(playbackProvider.notifier)
          .playTrackStreamAndSetQueue(track, tracks);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Cannot play stream: $e')));
    }
  }

  void _addToStreamQueue(Track track) {
    ref.read(playbackProvider.notifier).addToQueue(track);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Added "${track.name}" to play queue')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final trackState = ref.watch(trackProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final tracks = trackState.tracks;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          style: TextStyle(color: colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: 'Search tracks...',
            hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
          ),
          onSubmitted: (_) => _search(),
          autofocus: widget.query.isEmpty,
        ),
        actions: [
          IconButton(icon: const Icon(Icons.search), onPressed: _search),
        ],
      ),
      body: Column(
        children: [
          if (trackState.isLoading)
            LinearProgressIndicator(color: colorScheme.primary),
          if (trackState.error != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                trackState.error!,
                style: TextStyle(color: colorScheme.error),
              ),
            ),
          Expanded(
            child: tracks.isEmpty
                ? _buildEmptyState(colorScheme)
                : ListView.builder(
                    itemCount: tracks.length,
                    itemBuilder: (context, index) =>
                        _buildTrackTile(tracks[index], colorScheme),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ColorScheme colorScheme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            'Search for tracks',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackTile(Track track, ColorScheme colorScheme) {
    return ListTile(
      leading: track.coverUrl != null
          ? ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: track.coverUrl!,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                memCacheWidth: 144,
                memCacheHeight: 144,
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
      title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            track.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          Text(
            track.albumName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.play_arrow_rounded),
            tooltip: 'Play stream',
            onPressed: () => _playTrack(track),
          ),
          IconButton(
            icon: const Icon(Icons.playlist_add_rounded, size: 20),
            tooltip: 'Add to play queue',
            onPressed: () => _addToStreamQueue(track),
          ),
        ],
      ),
      onTap: () => _downloadTrack(track),
    );
  }
}
