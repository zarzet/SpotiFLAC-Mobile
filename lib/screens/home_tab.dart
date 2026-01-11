import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/track_provider.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/screens/track_metadata_screen.dart';
import 'package:spotiflac_android/screens/album_screen.dart';
import 'package:spotiflac_android/screens/artist_screen.dart';
import 'package:spotiflac_android/services/csv_import_service.dart';
import 'package:spotiflac_android/screens/playlist_screen.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/widgets/download_service_picker.dart';

class HomeTab extends ConsumerStatefulWidget {
  const HomeTab({super.key});
  @override
  ConsumerState<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends ConsumerState<HomeTab> with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  final _urlController = TextEditingController();
  bool _isTyping = false;
  final FocusNode _searchFocusNode = FocusNode();
  String? _lastSearchQuery; // Track last searched query to avoid duplicate searches
  
  @override
  bool get wantKeepAlive => true;
  
  @override
  void initState() {
    super.initState();
    _urlController.addListener(_onSearchChanged);
  }
  
  @override
  void dispose() {
    _urlController.removeListener(_onSearchChanged);
    _urlController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  /// Called when trackState changes - used to sync search bar with state
  void _onTrackStateChanged(TrackState? previous, TrackState next) {
    // If state was cleared (no content, no search text, not loading), clear the search bar
    // BUT only if search field is not focused (to prevent clearing while user is typing)
    if (previous != null && 
        !next.hasContent && 
        !next.hasSearchText && 
        !next.isLoading &&
        _urlController.text.isNotEmpty &&
        !_searchFocusNode.hasFocus) {
      _urlController.clear();
      setState(() => _isTyping = false);
    }
  }  void _onSearchChanged() {
    final text = _urlController.text.trim();
    
    // Update search text state for MainShell back button handling
    ref.read(trackProvider.notifier).setSearchText(text.isNotEmpty);
    
    // Update typing state immediately for UI transition
    if (text.isNotEmpty && !_isTyping) {
      setState(() => _isTyping = true);
    } else if (text.isEmpty && _isTyping) {
      setState(() => _isTyping = false);
      // Don't clear provider here - it causes focus issues
      // Provider will be cleared when user explicitly clears or navigates away
      return;
    }
    
    // No auto-search - user must press Enter to search
    // This saves API calls and avoids rate limiting
  }

  Future<void> _performSearch(String query) async {
    final settings = ref.read(settingsProvider);
    final searchProvider = settings.searchProvider;
    
    // Skip if same query already searched with same provider
    final searchKey = '${searchProvider ?? 'default'}:$query';
    if (_lastSearchQuery == searchKey) return;
    _lastSearchQuery = searchKey;
    
    if (searchProvider != null && searchProvider.isNotEmpty) {
      // Use custom search from extension
      await ref.read(trackProvider.notifier).customSearch(searchProvider, query);
    } else {
      // Use default search (Deezer/Spotify)
      await ref.read(trackProvider.notifier).search(query, metadataSource: settings.metadataSource);
    }
    ref.read(settingsProvider.notifier).setHasSearchedBefore();
  }

  Future<void> _pasteFromClipboard() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (data?.text != null) {
      _urlController.text = data!.text!;
      // For URLs, trigger fetch immediately after paste
      final text = data.text!.trim();
      if (text.startsWith('http') || text.startsWith('spotify:')) {
        _fetchMetadata();
      }
    }
  }

  Future<void> _clearAndRefresh() async {
    _urlController.clear();
    _searchFocusNode.unfocus();
    _lastSearchQuery = null; // Reset last query
    setState(() => _isTyping = false);
    ref.read(trackProvider.notifier).clear();
  }

  Future<void> _fetchMetadata() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) return;
    if (url.startsWith('http') || url.startsWith('spotify:')) {
      await ref.read(trackProvider.notifier).fetchFromUrl(url);
      _navigateToDetailIfNeeded();
    } else {
      final settings = ref.read(settingsProvider);
      await ref.read(trackProvider.notifier).search(url, metadataSource: settings.metadataSource);
    }
    ref.read(settingsProvider.notifier).setHasSearchedBefore();
  }

  /// Navigate to detail screen based on fetched content type
  void _navigateToDetailIfNeeded() {
    final trackState = ref.read(trackProvider);
    
    // Navigate to Album screen
    if (trackState.albumId != null && trackState.albumName != null && trackState.tracks.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => AlbumScreen(
        albumId: trackState.albumId!,
        albumName: trackState.albumName!,
        coverUrl: trackState.coverUrl,
        tracks: trackState.tracks,
      )));
      ref.read(trackProvider.notifier).clear();
      _urlController.clear();
      setState(() => _isTyping = false);
      return;
    }
    
    // Navigate to Playlist screen
    if (trackState.playlistName != null && trackState.tracks.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => PlaylistScreen(
        playlistName: trackState.playlistName!,
        coverUrl: trackState.coverUrl,
        tracks: trackState.tracks,
      )));
      ref.read(trackProvider.notifier).clear();
      _urlController.clear();
      setState(() => _isTyping = false);
      return;
    }
    
    // Navigate to Artist screen
    if (trackState.artistId != null && trackState.artistName != null && trackState.artistAlbums != null) {
      Navigator.push(context, MaterialPageRoute(builder: (context) => ArtistScreen(
        artistId: trackState.artistId!,
        artistName: trackState.artistName!,
        coverUrl: trackState.coverUrl,
        albums: trackState.artistAlbums!,
      )));
      ref.read(trackProvider.notifier).clear();
      _urlController.clear();
      setState(() => _isTyping = false);
      return;
    }
  }

  void _downloadTrack(int index) {
    final trackState = ref.read(trackProvider);
    if (index >= 0 && index < trackState.tracks.length) {
      final track = trackState.tracks[index];
      final settings = ref.read(settingsProvider);
      
      if (settings.askQualityBeforeDownload) {
        DownloadServicePicker.show(
          context,
          trackName: track.name,
          artistName: track.artistName,
          coverUrl: track.coverUrl,
          onSelect: (quality, service) {
            ref.read(downloadQueueProvider.notifier).addToQueue(track, service, qualityOverride: quality);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "${track.name}" to queue')));
          },
        );
      } else {
        ref.read(downloadQueueProvider.notifier).addToQueue(track, settings.defaultService);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added "${track.name}" to queue')));
      }
    }
  }

  Future<void> _importCsv(BuildContext context, WidgetRef ref) async {
    // Show loading dialog with progress
    int currentProgress = 0;
    int totalTracks = 0;
    
    // Use StatefulBuilder to update dialog content
    bool dialogShown = false;
    StateSetter? setDialogState;
    
    void showProgressDialog() {
      if (dialogShown || !mounted) return;
      dialogShown = true;
      showDialog(
        context: this.context,
        barrierDismissible: false,
        builder: (dialogCtx) => StatefulBuilder(
          builder: (dialogCtx, setState) {
            setDialogState = setState;
            return AlertDialog(
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    totalTracks > 0 
                        ? 'Fetching metadata... $currentProgress/$totalTracks'
                        : 'Reading CSV...',
                  ),
                ],
              ),
            );
          },
        ),
      );
    }
    
    final tracks = await CsvImportService.pickAndParseCsv(
      onProgress: (current, total) {
        currentProgress = current;
        totalTracks = total;
        if (!dialogShown && total > 0) {
          showProgressDialog();
        }
        setDialogState?.call(() {});
      },
    );
    
    // Close progress dialog
    if (dialogShown && mounted) {
      Navigator.of(this.context).pop();
    }
    
    if (tracks.isNotEmpty) {
      final settings = ref.read(settingsProvider);
      
      if (!mounted) return;
      
      // Optionally show confirmation dialog
      final confirmed = await showDialog<bool>(
        context: this.context,
        builder: (dialogCtx) => AlertDialog(
          title: const Text('Import Playlist'),
          content: Text('Found ${tracks.length} tracks in CSV. Add them to download queue?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogCtx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogCtx, true),
              child: const Text('Import'),
            ),
          ],
        ),
      );

      if (confirmed == true) {
        ref.read(downloadQueueProvider.notifier).addMultipleToQueue(tracks, settings.defaultService);
        if (mounted) {
           ScaffoldMessenger.of(this.context).showSnackBar(
            SnackBar(
              content: Text('Added ${tracks.length} tracks to queue'),
              action: SnackBarAction(
                label: 'View Queue',
                onPressed: () {
                   // Navigate to queue tab (handled by main_shell index)
                   // We don't have direct access to set index here easily without provider
                },
              ),
            ),
          );
        }
      }
    } else {
       // Only show error if pick was not cancelled (handled inside service logging usually, but maybe show snackbar if file empty)
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    // Listen for state changes to sync search bar and auto-navigate
    ref.listen<TrackState>(trackProvider, (previous, next) {
      _onTrackStateChanged(previous, next);
      // Auto-navigate when URL fetch completes
      if (previous != null && previous.isLoading && !next.isLoading && next.error == null) {
        _navigateToDetailIfNeeded();
      }
    });
    
    // Use select() to only rebuild when specific fields change
    final tracks = ref.watch(trackProvider.select((s) => s.tracks));
    final searchArtists = ref.watch(trackProvider.select((s) => s.searchArtists));
    final isLoading = ref.watch(trackProvider.select((s) => s.isLoading));
    final error = ref.watch(trackProvider.select((s) => s.error));
    final hasSearchedBefore = ref.watch(settingsProvider.select((s) => s.hasSearchedBefore));
    
    final colorScheme = Theme.of(context).colorScheme;
    final hasResults = _isTyping || tracks.isNotEmpty || (searchArtists != null && searchArtists.isNotEmpty) || isLoading;
    final screenHeight = MediaQuery.of(context).size.height;
    final topPadding = MediaQuery.of(context).padding.top;
    final historyItems = ref.watch(downloadHistoryProvider.select((s) => s.items));

    return Scaffold(
      body: CustomScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        slivers: [
          // App Bar - always present
          SliverAppBar(
            expandedHeight: 120 + topPadding,
            collapsedHeight: kToolbarHeight,
            floating: false,
            pinned: true,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: Colors.transparent,
            automaticallyImplyLeading: false,
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final maxHeight = 120 + topPadding;
                final minHeight = kToolbarHeight + topPadding;
                final expandRatio = ((constraints.maxHeight - minHeight) / (maxHeight - minHeight)).clamp(0.0, 1.0);
                
                return FlexibleSpaceBar(
                  expandedTitleScale: 1.0,
                  titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                  title: Text(
                    'Home',
                    style: TextStyle(
                      fontSize: 20 + (14 * expandRatio), // 20 -> 34
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Idle content (logo, title) - always in tree, animated size
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: hasResults
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        SizedBox(height: screenHeight * 0.06),
                        Container(
                          width: 96,
                          height: 96,
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Image.asset(
                            'assets/images/logo-transparant.png',
                            color: colorScheme.onPrimary, // Tint with onPrimary color
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => ClipRRect(
                              // Fallback to original logo if transparent one is missing
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/logo.png',
                                width: 96,
                                height: 96,
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'SpotiFLAC',
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
                      ],
                    ),
            ),
          ),
          
          // Search bar - always present at same position in tree
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(16, hasResults ? 8 : 32, 16, hasResults ? 8 : 16),
              child: _buildSearchBar(colorScheme),
            ),
          ),
          
          // Idle content below search bar - always in tree
          SliverToBoxAdapter(
            child: AnimatedSize(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
              child: hasResults
                  ? const SizedBox.shrink()
                  : Column(
                      children: [
                        if (!hasSearchedBefore)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Supports: Track, Album, Playlist, Artist URLs',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        if (historyItems.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                            child: _buildRecentDownloads(historyItems, colorScheme),
                          ),
                      ],
                    ),
            ),
          ),
          
          // Results content - search results only (albums/artists/playlists navigate to separate screens)
          ..._buildSearchResults(
            tracks: tracks,
            searchArtists: searchArtists,
            isLoading: isLoading,
            error: error,
            colorScheme: colorScheme,
            hasResults: hasResults,
          ),
        ],
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
          height: 130,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayItems.length,
            itemBuilder: (context, index) {
              final item = displayItems[index];
              return KeyedSubtree(
                key: ValueKey(item.id),
                child: GestureDetector(
                  onTap: () => _navigateToMetadataScreen(item),
                  child: Container(
                    width: 100,
                    margin: const EdgeInsets.only(right: 12),
                    child: Column(
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: item.coverUrl != null
                              ? CachedNetworkImage(
                                  imageUrl: item.coverUrl!,
                                  width: 100,
                                  height: 100,
                                  fit: BoxFit.cover,
                                  memCacheWidth: 200,
                                  memCacheHeight: 200,
                                )
                              : Container(
                                  width: 100,
                                  height: 100,
                                  color: colorScheme.surfaceContainerHighest,
                                  child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant, size: 32),
                                ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          item.trackName,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
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
                      'Rate Limited',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Too many requests. Please wait a moment before searching again.',
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
    
    // Default error display
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

  // Search results slivers - only shows search results (track list)
  List<Widget> _buildSearchResults({
    required List<Track> tracks,
    required List<SearchArtist>? searchArtists,
    required bool isLoading,
    required String? error,
    required ColorScheme colorScheme,
    required bool hasResults,
  }) {
    if (!hasResults) {
      return [const SliverToBoxAdapter(child: SizedBox.shrink())];
    }
    
    return [
      // Error message - with special handling for rate limit (429)
      if (error != null)
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: _buildErrorWidget(error, colorScheme),
        )),

      // Loading indicator
      if (isLoading)
        const SliverToBoxAdapter(child: Padding(padding: EdgeInsets.symmetric(horizontal: 16), child: LinearProgressIndicator())),

      // Artist search results (horizontal scroll)
      if (searchArtists != null && searchArtists.isNotEmpty)
        SliverToBoxAdapter(child: _buildArtistSearchResults(searchArtists, colorScheme)),

      // Songs section header
      if (tracks.isNotEmpty)
        SliverToBoxAdapter(child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('Songs', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        )),

      // Track list in grouped card
      if (tracks.isNotEmpty)
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Color.alphaBlend(Colors.white.withValues(alpha: 0.08), colorScheme.surface)
                  : colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            clipBehavior: Clip.antiAlias,
            child: Material(
              color: Colors.transparent,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  for (int i = 0; i < tracks.length; i++)
                    _TrackItemWithStatus(
                      key: ValueKey(tracks[i].id),
                      track: tracks[i],
                      index: i,
                      showDivider: i < tracks.length - 1,
                      onDownload: () => _downloadTrack(i),
                    ),
                ],
              ),
            ),
          ),
        ),

      // Bottom padding
      const SliverToBoxAdapter(child: SizedBox(height: 16)),
    ];
  }

  Widget _buildArtistSearchResults(List<SearchArtist> artists, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Text('Artists', style: Theme.of(context).textTheme.titleSmall?.copyWith(color: colorScheme.onSurfaceVariant)),
        ),
        SizedBox(
          height: 160,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: artists.length,
            itemBuilder: (context, index) {
              final artist = artists[index];
              return KeyedSubtree(
                key: ValueKey(artist.id),
                child: _buildArtistCard(artist, colorScheme),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildArtistCard(SearchArtist artist, ColorScheme colorScheme) {
    // Validate image URL - must be non-null, non-empty, and have a valid host
    final hasValidImage = artist.imageUrl != null && 
                          artist.imageUrl!.isNotEmpty &&
                          Uri.tryParse(artist.imageUrl!)?.hasAuthority == true;
    
    return GestureDetector(
      onTap: () => _navigateToArtist(artist.id, artist.name, artist.imageUrl),
      child: Container(
        width: 110,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.surfaceContainerHighest,
              ),
              child: ClipOval(
                child: hasValidImage
                    ? CachedNetworkImage(
                        imageUrl: artist.imageUrl!,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
                        errorWidget: (context, url, error) => Icon(
                          Icons.person,
                          color: colorScheme.onSurfaceVariant,
                          size: 44,
                        ),
                      )
                    : Icon(Icons.person, color: colorScheme.onSurfaceVariant, size: 44),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              artist.name,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToArtist(String artistId, String artistName, String? imageUrl) {
    // Navigate immediately with data from search, fetch albums in ArtistScreen
    ref.read(settingsProvider.notifier).setHasSearchedBefore();
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => ArtistScreen(
        artistId: artistId,
        artistName: artistName,
        coverUrl: imageUrl,
        // albums: null - will be fetched in ArtistScreen
      ),
    ));
  }

  /// Get search hint based on selected provider
  String _getSearchHint() {
    final settings = ref.read(settingsProvider);
    final searchProvider = settings.searchProvider;
    
    if (searchProvider != null && searchProvider.isNotEmpty) {
      final extState = ref.read(extensionProvider);
      final ext = extState.extensions.where((e) => e.id == searchProvider).firstOrNull;
      if (ext?.searchBehavior?.placeholder != null) {
        return ext!.searchBehavior!.placeholder!;
      }
      return 'Search with ${ext?.displayName ?? 'extension'}...';
    }
    return 'Paste Spotify URL or search...';
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    final hasText = _urlController.text.isNotEmpty;
    
    return TextField(
      controller: _urlController,
      focusNode: _searchFocusNode,
      autofocus: false,
      decoration: InputDecoration(
        hintText: _getSearchHint(),
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
        prefixIcon: const Icon(Icons.search),
        suffixIcon: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasText)
              IconButton(
                icon: const Icon(Icons.clear),
                onPressed: _clearAndRefresh,
                tooltip: 'Clear',
              )
            else ...[
              IconButton(
                icon: const Icon(Icons.file_upload_outlined),
                onPressed: () => _importCsv(context, ref),
                tooltip: 'Import CSV',
              ),
              IconButton(
                icon: const Icon(Icons.paste),
                onPressed: _pasteFromClipboard,
                tooltip: 'Paste',
              ),
            ],
          ],
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      ),
      onSubmitted: (_) => _onSearchSubmitted(),
    );
  }

  /// Handle Enter key press - search or fetch URL
  void _onSearchSubmitted() {
    final text = _urlController.text.trim();
    if (text.isEmpty) return;
    
    // If it's a URL, fetch metadata
    if (text.startsWith('http') || text.startsWith('spotify:')) {
      _fetchMetadata();
      _searchFocusNode.unfocus();
      return;
    }
    
    // For search queries, always search (minimum 2 chars)
    if (text.length >= 2) {
      _performSearch(text);
    }
    _searchFocusNode.unfocus();
  }

}

/// Separate Consumer widget for each track item - only rebuilds when this specific track's status changes
class _TrackItemWithStatus extends ConsumerWidget {
  final Track track;
  final int index;
  final bool showDivider;
  final VoidCallback onDownload;

  const _TrackItemWithStatus({
    super.key,
    required this.track,
    required this.index,
    required this.showDivider,
    required this.onDownload,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    
    // Only watch the specific item for this track using select()
    final queueItem = ref.watch(downloadQueueProvider.select((state) {
      return state.items.where((item) => item.track.id == track.id).firstOrNull;
    }));
    
    // Check if track is in history (already downloaded before)
    final isInHistory = ref.watch(downloadHistoryProvider.select((state) {
      return state.isDownloaded(track.id);
    }));
    
    // Get thumbnail size from extension if track is from extension
    double thumbWidth = 56;
    double thumbHeight = 56;
    
    // Get extension ID from track.source or from TrackState.searchExtensionId
    final trackState = ref.watch(trackProvider);
    final extensionId = track.source ?? trackState.searchExtensionId;
    
    if (extensionId != null && extensionId.isNotEmpty) {
      final extState = ref.watch(extensionProvider);
      final extension = extState.extensions.where((e) => e.id == extensionId).firstOrNull;
      if (extension?.searchBehavior != null) {
        final size = extension!.searchBehavior!.getThumbnailSize(defaultSize: 56);
        thumbWidth = size.$1;
        thumbHeight = size.$2;
        // Debug: log only when using custom size
        if (thumbWidth != 56 || thumbHeight != 56) {
          debugPrint('[Thumbnail] ${track.name}: using ${thumbWidth.toInt()}x${thumbHeight.toInt()} from ${extension.id}');
        }
      }
    }
    
    final isQueued = queueItem != null;
    final isDownloading = queueItem?.status == DownloadStatus.downloading;
    final isFinalizing = queueItem?.status == DownloadStatus.finalizing;
    final isCompleted = queueItem?.status == DownloadStatus.completed;
    final progress = queueItem?.progress ?? 0.0;
    
    // Show as downloaded if in queue completed OR in history
    final showAsDownloaded = isCompleted || (!isQueued && isInHistory);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _handleTap(context, ref, isQueued: isQueued, isInHistory: isInHistory),
          splashColor: colorScheme.primary.withValues(alpha: 0.12),
          highlightColor: colorScheme.primary.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                // Album art with dynamic size based on extension config
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: track.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: track.coverUrl!,
                          width: thumbWidth,
                          height: thumbHeight,
                          fit: BoxFit.cover,
                          memCacheWidth: (thumbWidth * 2).toInt(),
                          memCacheHeight: (thumbHeight * 2).toInt(),
                        )
                      : Container(
                          width: thumbWidth,
                          height: thumbHeight,
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
                        ),
                ),
                const SizedBox(width: 12),
                // Track info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.name,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.artistName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Download button / status indicator
                _buildDownloadButton(context, ref, colorScheme, isQueued: isQueued, isDownloading: isDownloading, isFinalizing: isFinalizing, showAsDownloaded: showAsDownloaded, isInHistory: isInHistory, progress: progress),
              ],
            ),
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: thumbWidth + 24, // Adjust divider indent based on thumbnail width
            endIndent: 12,
            color: colorScheme.outlineVariant.withValues(alpha: 0.3),
          ),
      ],
    );
  }

  void _handleTap(BuildContext context, WidgetRef ref, {required bool isQueued, required bool isInHistory}) async {
    // If already in queue, do nothing
    if (isQueued) return;
    
    // If in history, check if file still exists
    if (isInHistory) {
      final historyItem = ref.read(downloadHistoryProvider.notifier).getBySpotifyId(track.id);
      if (historyItem != null) {
        final fileExists = await File(historyItem.filePath).exists();
        if (fileExists) {
          // File exists, show snackbar
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('"${track.name}" already downloaded')),
            );
          }
          return;
        } else {
          // File doesn't exist, remove from history and allow download
          ref.read(downloadHistoryProvider.notifier).removeBySpotifyId(track.id);
        }
      }
    }
    
    // Proceed with download
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
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: colorScheme.primaryContainer, shape: BoxShape.circle),
          child: Icon(Icons.check, color: colorScheme.onPrimaryContainer, size: iconSize),
        ),
      );
    } else if (isFinalizing) {
      // Show finalizing status (embedding metadata)
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
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest, shape: BoxShape.circle),
        child: Icon(Icons.hourglass_empty, color: colorScheme.onSurfaceVariant, size: iconSize),
      );
    } else {
      return GestureDetector(
        onTap: onDownload,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(color: colorScheme.secondaryContainer, shape: BoxShape.circle),
          child: Icon(Icons.download, color: colorScheme.onSecondaryContainer, size: iconSize),
        ),
      );
    }
  }
}
