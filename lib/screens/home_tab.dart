import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/providers/track_provider.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/screens/track_metadata_screen.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});
  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final _urlController = TextEditingController();
  
  @override
  bool get wantKeepAlive => true;
  @override
  void dispose() { _urlController.dispose(); super.dispose(); }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) _urlController.text = data!.text!;
  }

  Future<void> _clearAndRefresh() async {
    _urlController.clear();
    ref.read(trackProvider.notifier).clear();
    await Future.delayed(const Duration(milliseconds: 300));
  }

  Future<void> _fetchMetadata() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (url.startsWith('http') || url.startsWith('spotify:')) {
      await ref.read(trackProvider.notifier).fetchFromUrl(url);
    } else {
      await ref.read(trackProvider.notifier).search(url);
    }
    ref.read(settingsProvider.notifier).setHasSearchedBefore();
  }

  void _downloadTrack(int index) {
    final trackState = ref.read(trackProvider);
    if (index >= 0 && index < trackState.tracks.length) {
      final track = trackState.tracks[index];
      final settings = ref.read(settingsProvider);
      ref.read(downloadQueueProvider.notifier).addToQueue(track, settings.defaultService);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "${track.name}" to queue')));
    }
  }

  void _downloadAll() {
    final trackState = ref.read(trackProvider);
    if (trackState.tracks.isEmpty) return;
    final settings = ref.read(settingsProvider);
    ref.read(downloadQueueProvider.notifier).addMultipleToQueue(trackState.tracks, settings.defaultService);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${trackState.tracks.length} tracks to queue')));
  }

  bool get _hasResults {
    final trackState = ref.watch(trackProvider);
    return trackState.tracks.isNotEmpty || trackState.artistAlbums != null || trackState.isLoading;
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final trackState = ref.watch(trackProvider);
    final colorScheme = Theme.of(context).colorScheme;
    final hasResults = _hasResults;

    return Scaffold(
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: hasResults 
              ? _buildResultsView(trackState, colorScheme)
              : _buildCenteredSearch(colorScheme),
        ),
      ),
    );
  }

  // Centered search view when no results
  Widget _buildCenteredSearch(ColorScheme colorScheme) {
    final historyItems = ref.watch(downloadHistoryProvider).items;
    
    return Center(
      key: const ValueKey('centered'),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // App icon/logo
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer.withValues(alpha: 0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.music_note, size: 48, color: colorScheme.primary),
            ),
            const SizedBox(height: 24),
            Text(
              'Search Music',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Paste a Spotify link or search by name',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 32),
            // Search bar
            _buildSearchBar(colorScheme),
            const SizedBox(height: 12),
            // Helper text
            if (!ref.watch(settingsProvider).hasSearchedBefore)
              Text(
                'Supports: Track, Album, Playlist, Artist URLs',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            // Recent downloads - compact horizontal scroll
            if (historyItems.isNotEmpty) ...[
              const SizedBox(height: 32),
              _buildRecentDownloads(historyItems, colorScheme),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildRecentDownloads(List<DownloadHistoryItem> items, ColorScheme colorScheme) {
    final displayItems = items.take(10).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: Text(
            'Recent',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        SizedBox(
          height: 80,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final item = displayItems[index];
              return GestureDetector(
                onTap: () => _navigateToMetadataScreen(item),
                child: Container(
                  width: 60,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: item.coverUrl != null
                            ? CachedNetworkImage(
                                imageUrl: item.coverUrl!,
                                width: 56,
                                height: 56,
                                fit: BoxFit.cover,
                                memCacheWidth: 112,
                                memCacheHeight: 112,
                              )
                            : Container(
                                width: 56,
                                height: 56,
                                color: colorScheme.surfaceContainerHighest,
                                child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant, size: 24),
                              ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.trackName,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  void _navigateToMetadataScreen(DownloadHistoryItem item) {
    Navigator.push(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => TrackMetadataScreen(item: item),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  // Results view with search bar at top
  Widget _buildResultsView(TrackState trackState, ColorScheme colorScheme) {
    return RefreshIndicator(
      key: const ValueKey('results'),
      onRefresh: _clearAndRefresh,
      displacement: 100,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          // Collapsing App Bar
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
                'Search',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // Search bar at top
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: _buildSearchBar(colorScheme),
            ),
          ),

          // Error message
          if (trackState.error != null)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(trackState.error!, style: TextStyle(color: colorScheme.error)),
            )),

          // Loading indicator
          if (trackState.isLoading)
            const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: LinearProgressIndicator())),

          // Album/Playlist header
          if (trackState.albumName != null || trackState.playlistName != null)
            SliverToBoxAdapter(child: _buildHeader(trackState, colorScheme)),

          // Artist header and discography
          if (trackState.artistName != null && trackState.artistAlbums != null)
            SliverToBoxAdapter(child: _buildArtistHeader(trackState, colorScheme)),

          if (trackState.artistAlbums != null && trackState.artistAlbums!.isNotEmpty)
            SliverToBoxAdapter(child: _buildArtistDiscography(trackState, colorScheme)),

          // Download All button
          if (trackState.tracks.length > 1 && trackState.albumName == null && trackState.playlistName == null && trackState.artistAlbums == null)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: FilledButton.icon(onPressed: _downloadAll, icon: const Icon(Icons.download),
                label: Text('Download All (${trackState.tracks.length})'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48))),
            )),

          // Track list
          SliverList(delegate: SliverChildBuilderDelegate(
            (context, index) => _buildTrackTile(index, colorScheme),
            childCount: trackState.tracks.length,
          )),

          // Bottom padding
          const SliverToBoxAdapter(child: SizedBox(height: 16)),
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return TextField(
      controller: _urlController,
      decoration: InputDecoration(
        hintText: 'Paste Spotify URL or search...',
        filled: true,
        fillColor: colorScheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: colorScheme.outline.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(28),
          borderSide: BorderSide(color: colorScheme.primary, width: 2),
        ),
        prefixIcon: const Icon(Icons.link),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.paste),
              onPressed: _pasteFromClipboard,
              tooltip: 'Paste',
            ),
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.primary,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.search, color: colorScheme.onPrimary, size: 20),
                ),
                onPressed: _fetchMetadata,
                tooltip: 'Search',
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      onSubmitted: (_) => _fetchMetadata(),
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
              ClipRRect(borderRadius: BorderRadius.circular(12),
                child: CachedNetworkImage(imageUrl: state.coverUrl!, width: 80, height: 80, fit: BoxFit.cover,
                  placeholder: (_, _) => Container(width: 80, height: 80, color: colorScheme.surfaceContainerHighest))),
            const SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(state.albumName ?? state.playlistName ?? '',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                maxLines: 2, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              Text('${state.tracks.length} tracks',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant)),
            ])),
            FilledButton.tonal(onPressed: _downloadAll,
              style: FilledButton.styleFrom(shape: const CircleBorder(), padding: const EdgeInsets.all(16)),
              child: const Icon(Icons.download)),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistHeader(TrackState state, ColorScheme colorScheme) {
    final albumCount = state.artistAlbums?.length ?? 0;
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            if (state.coverUrl != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(40),
                child: CachedNetworkImage(
                  imageUrl: state.coverUrl!,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Container(
                    width: 80,
                    height: 80,
                    color: colorScheme.surfaceContainerHighest,
                    child: Icon(Icons.person, color: colorScheme.onSurfaceVariant),
                  ),
                ),
              ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    state.artistName ?? '',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$albumCount releases',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildArtistDiscography(TrackState state, ColorScheme colorScheme) {
    final albums = state.artistAlbums ?? [];
    
    final albumsOnly = albums.where((a) => a.albumType == 'album').toList();
    final singles = albums.where((a) => a.albumType == 'single').toList();
    final compilations = albums.where((a) => a.albumType == 'compilation').toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (albumsOnly.isNotEmpty) _buildAlbumSection('Albums', albumsOnly, colorScheme),
        if (singles.isNotEmpty) _buildAlbumSection('Singles & EPs', singles, colorScheme),
        if (compilations.isNotEmpty) _buildAlbumSection('Compilations', compilations, colorScheme),
      ],
    );
  }

  Widget _buildAlbumSection(String title, List<ArtistAlbum> albums, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text(
            '$title (${albums.length})',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.primary,
            ),
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: albums.length,
            itemBuilder: (context, index) => _buildAlbumCard(albums[index], colorScheme),
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumCard(ArtistAlbum album, ColorScheme colorScheme) {
    return GestureDetector(
      onTap: () => _fetchAlbum(album.id),
      child: Container(
        width: 130,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: album.coverUrl != null
                  ? CachedNetworkImage(
                      imageUrl: album.coverUrl!,
                      width: 130,
                      height: 130,
                      fit: BoxFit.cover,
                      memCacheWidth: 260,
                      memCacheHeight: 260,
                    )
                  : Container(
                      width: 130,
                      height: 130,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.album, color: colorScheme.onSurfaceVariant),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              '${album.releaseDate.length >= 4 ? album.releaseDate.substring(0, 4) : album.releaseDate} • ${album.totalTracks} tracks',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _fetchAlbum(String albumId) {
    // Use fetchAlbumFromArtist to save artist state for back navigation
    ref.read(trackProvider.notifier).fetchAlbumFromArtist(albumId);
    ref.read(settingsProvider.notifier).setHasSearchedBefore();
  }

  Widget _buildTrackTile(int index, ColorScheme colorScheme) {
    final track = ref.watch(trackProvider).tracks[index];
    return ListTile(
      leading: track.coverUrl != null
          ? ClipRRect(borderRadius: BorderRadius.circular(8),
              child: CachedNetworkImage(
                imageUrl: track.coverUrl!, 
                width: 48, 
                height: 48, 
                fit: BoxFit.cover,
                memCacheWidth: 96,
                memCacheHeight: 96,
              ))
          : Container(width: 48, height: 48,
              decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
              child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant)),
      title: Text(track.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(track.artistName, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: colorScheme.onSurfaceVariant)),
      trailing: IconButton(icon: Icon(Icons.download, color: colorScheme.primary), onPressed: () => _downloadTrack(index)),
      onTap: () => _downloadTrack(index),
    );
  }
}
