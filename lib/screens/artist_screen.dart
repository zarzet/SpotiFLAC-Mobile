import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/providers/track_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/recent_access_provider.dart';
import 'package:spotiflac_android/providers/local_library_provider.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/file_access.dart';
import 'package:spotiflac_android/screens/album_screen.dart';
import 'package:spotiflac_android/screens/home_tab.dart' show ExtensionAlbumScreen;
import 'package:spotiflac_android/widgets/download_service_picker.dart';

/// Simple in-memory cache for artist data
class _ArtistCache {
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _ttl = Duration(minutes: 10);

  static _CacheEntry? get(String artistId) {
    final entry = _cache[artistId];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(artistId);
      return null;
    }
    return entry;
  }

  static void set(String artistId, {
    required List<ArtistAlbum> albums,
    List<Track>? topTracks,
    String? headerImageUrl,
    int? monthlyListeners,
  }) {
    _cache[artistId] = _CacheEntry(
      albums: albums,
      topTracks: topTracks,
      headerImageUrl: headerImageUrl,
      monthlyListeners: monthlyListeners,
      expiresAt: DateTime.now().add(_ttl),
    );
  }
}

class _CacheEntry {
  final List<ArtistAlbum> albums;
  final List<Track>? topTracks;
  final String? headerImageUrl;
  final int? monthlyListeners;
  final DateTime expiresAt;
  
  _CacheEntry({
    required this.albums,
    this.topTracks,
    this.headerImageUrl,
    this.monthlyListeners,
    required this.expiresAt,
  });
}

/// Artist screen with Spotify-like design
class ArtistScreen extends ConsumerStatefulWidget {
  final String artistId;
  final String artistName;
  final String? coverUrl;
  final String? headerImageUrl;
  final int? monthlyListeners;
  final List<ArtistAlbum>? albums;
  final List<Track>? topTracks;
  final String? extensionId;

  const ArtistScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.coverUrl,
    this.headerImageUrl,
    this.monthlyListeners,
    this.albums,
    this.topTracks,
    this.extensionId,
  });

  @override
  ConsumerState<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends ConsumerState<ArtistScreen> {
  bool _isLoadingDiscography = false;
  List<ArtistAlbum>? _albums;
  List<Track>? _topTracks;
  String? _headerImageUrl;
  int? _monthlyListeners;
  String? _error;
  
  bool _showTitleInAppBar = false;
  final ScrollController _scrollController = ScrollController();

  bool _isSelectionMode = false;
  final Set<String> _selectedAlbumIds = {};
  bool _isFetchingDiscography = false;

@override
  void initState() {
    super.initState();
    
    _scrollController.addListener(_onScroll);
    
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final providerId = widget.extensionId ?? 
                        (widget.artistId.startsWith('deezer:') ? 'deezer' : 'spotify');
      ref.read(recentAccessProvider.notifier).recordArtistAccess(
        id: widget.artistId,
        name: widget.artistName,
        imageUrl: widget.coverUrl,
        providerId: providerId,
      );
    });
    
    if (widget.extensionId != null) {
      _albums = widget.albums;
      _topTracks = widget.topTracks;
      _headerImageUrl = widget.headerImageUrl;
      _monthlyListeners = widget.monthlyListeners;
      return;
    }
    
    final cached = _ArtistCache.get(widget.artistId);
    
    if (widget.albums != null) {
      _albums = widget.albums;
      _topTracks = widget.topTracks;
      _headerImageUrl = widget.headerImageUrl;
      _monthlyListeners = widget.monthlyListeners;
      
      if (_topTracks == null || _topTracks!.isEmpty) {
        _fetchDiscography();
      }
    } else if (cached != null) {
      _albums = cached.albums;
      _topTracks = cached.topTracks;
      _headerImageUrl = cached.headerImageUrl;
      _monthlyListeners = cached.monthlyListeners;
      
      if (_topTracks == null || _topTracks!.isEmpty) {
        _fetchDiscography();
      }
    } else {
      _fetchDiscography();
}
  }

  void _onScroll() {
    // Show title when scrolled past the header (280px trigger)
    final shouldShow = _scrollController.offset > 280;
    if (shouldShow != _showTitleInAppBar) {
      setState(() => _showTitleInAppBar = shouldShow);
    }
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchDiscography() async {
    setState(() => _isLoadingDiscography = true);
    try {
      List<ArtistAlbum> albums;
      List<Track>? topTracks;
      String? headerImage;
      int? listeners;
      
      if (widget.artistId.startsWith('deezer:')) {
        final deezerArtistId = widget.artistId.replaceFirst('deezer:', '');
        final metadata = await PlatformBridge.getDeezerMetadata('artist', deezerArtistId);
        final albumsList = metadata['albums'] as List<dynamic>;
        albums = albumsList.map((a) => _parseArtistAlbum(a as Map<String, dynamic>)).toList();
      } else {
        final url = 'https://open.spotify.com/artist/${widget.artistId}';
        final result = await PlatformBridge.handleURLWithExtension(url);
        
        if (result != null && result['artist'] != null) {
          final artistData = result['artist'] as Map<String, dynamic>;
          final albumsList = artistData['albums'] as List<dynamic>? ?? [];
          albums = albumsList.map((a) => _parseArtistAlbum(a as Map<String, dynamic>)).toList();
          
          final topTracksList = artistData['top_tracks'] as List<dynamic>? ?? [];
          if (topTracksList.isNotEmpty) {
            topTracks = topTracksList.map((t) => _parseTrack(t as Map<String, dynamic>)).toList();
          }
          
          headerImage = artistData['header_image'] as String?;
          listeners = artistData['listeners'] as int?;
        } else {
          final metadata = await PlatformBridge.getSpotifyMetadataWithFallback(url);
          final albumsList = metadata['albums'] as List<dynamic>;
          albums = albumsList.map((a) => _parseArtistAlbum(a as Map<String, dynamic>)).toList();
        }
      }
      
      final finalHeaderImage = headerImage ?? _headerImageUrl ?? widget.headerImageUrl;
      final finalListeners = listeners ?? _monthlyListeners ?? widget.monthlyListeners;
      
      _ArtistCache.set(
        widget.artistId,
        albums: albums,
        topTracks: topTracks,
        headerImageUrl: finalHeaderImage,
        monthlyListeners: finalListeners,
      );
      
      if (mounted) {
        setState(() {
          _albums = albums;
          _topTracks = topTracks;
          _headerImageUrl = finalHeaderImage;
          _monthlyListeners = finalListeners;
          _isLoadingDiscography = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoadingDiscography = false;
        });
      }
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
      coverUrl: (data['cover_url'] ?? data['images'])?.toString(),
      isrc: data['isrc']?.toString(),
      duration: (durationMs / 1000).round(),
      trackNumber: data['track_number'] as int?,
      discNumber: data['disc_number'] as int?,
      releaseDate: data['release_date']?.toString(),
      source: data['provider_id']?.toString(),
    );
  }

  ArtistAlbum _parseArtistAlbum(Map<String, dynamic> data) {
    return ArtistAlbum(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      releaseDate: data['release_date'] as String? ?? '',
      totalTracks: data['total_tracks'] as int? ?? 0,
      coverUrl: (data['cover_url'] ?? data['images'])?.toString(),
      albumType: data['album_type'] as String? ?? 'album',
      artists: data['artists'] as String? ?? '',
      providerId: data['provider_id']?.toString(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final albums = _albums ?? [];
    final albumsOnly = albums.where((a) => a.albumType == 'album').toList();
    final singles = albums.where((a) => a.albumType == 'single').toList();
    final compilations = albums.where((a) => a.albumType == 'compilation').toList();

    final hasDiscography = !_isLoadingDiscography && _error == null && albums.isNotEmpty;

return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Scaffold(
      body: Stack(
        children: [
          CustomScrollView(
        controller: _scrollController,
        slivers: [
          _buildHeader(context, colorScheme, albums: albums, hasDiscography: hasDiscography),
          if (_isLoadingDiscography)
            const SliverToBoxAdapter(child: Padding(
              padding: EdgeInsets.all(32),
              child: Center(child: CircularProgressIndicator()),
            )),
          if (_error != null)
            SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.all(16),
              child: _buildErrorWidget(_error!, colorScheme),
            )),
          if (!_isLoadingDiscography && _error == null) ...[
            if (_topTracks != null && _topTracks!.isNotEmpty)
              SliverToBoxAdapter(child: _buildPopularSection(colorScheme)),
            if (albumsOnly.isNotEmpty) 
              SliverToBoxAdapter(child: _buildAlbumSection(context.l10n.artistAlbums, albumsOnly, colorScheme)),
            if (singles.isNotEmpty) 
              SliverToBoxAdapter(child: _buildAlbumSection(context.l10n.artistSingles, singles, colorScheme)),
            if (compilations.isNotEmpty) 
              SliverToBoxAdapter(child: _buildAlbumSection(context.l10n.artistCompilations, compilations, colorScheme)),
          ],
          SliverToBoxAdapter(child: SizedBox(height: _isSelectionMode ? 120 : 32)),
        ],
      ),
          if (_isSelectionMode)
            _buildSelectionBar(context, colorScheme, albums),
        ],
      ),
      ),
    );
  }

  void _exitSelectionMode() {
    HapticFeedback.lightImpact();
    setState(() {
      _isSelectionMode = false;
      _selectedAlbumIds.clear();
    });
  }

  void _enterSelectionMode(String albumId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedAlbumIds.add(albumId);
    });
  }

  void _toggleAlbumSelection(String albumId) {
    HapticFeedback.selectionClick();
    setState(() {
      if (_selectedAlbumIds.contains(albumId)) {
        _selectedAlbumIds.remove(albumId);
        if (_selectedAlbumIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedAlbumIds.add(albumId);
      }
    });
  }

  void _selectAll(List<ArtistAlbum> albums) {
    setState(() {
      _selectedAlbumIds.addAll(albums.map((a) => a.id));
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedAlbumIds.clear();
    });
  }

  Widget _buildSelectionBar(BuildContext context, ColorScheme colorScheme, List<ArtistAlbum> allAlbums) {
    final allSelected = _selectedAlbumIds.length == allAlbums.length;
    final selectedCount = _selectedAlbumIds.length;
    final selectedAlbums = allAlbums.where((a) => _selectedAlbumIds.contains(a.id)).toList();
    final totalTracks = selectedAlbums.fold<int>(0, (sum, a) => sum + a.totalTracks);

    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHigh,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                IconButton(
                  onPressed: _exitSelectionMode,
                  icon: const Icon(Icons.close),
                  tooltip: context.l10n.dialogCancel,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        context.l10n.discographySelectedCount(selectedCount),
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (selectedCount > 0)
                        Text(
                          context.l10n.tracksCount(totalTracks),
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: allSelected ? _deselectAll : () => _selectAll(allAlbums),
                  child: Text(allSelected ? context.l10n.actionDeselect : context.l10n.actionSelectAll),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: selectedCount > 0 ? () => _downloadSelectedAlbums(context, selectedAlbums) : null,
                  icon: const Icon(Icons.download, size: 18),
                  label: Text(context.l10n.discographyDownloadSelected),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDiscographyOptions(BuildContext context, ColorScheme colorScheme, List<ArtistAlbum> albums) {
    final albumsOnly = albums.where((a) => a.albumType == 'album').toList();
    final singles = albums.where((a) => a.albumType == 'single').toList();

    final totalTracks = albums.fold<int>(0, (sum, a) => sum + a.totalTracks);
    final albumTracks = albumsOnly.fold<int>(0, (sum, a) => sum + a.totalTracks);
    final singleTracks = singles.fold<int>(0, (sum, a) => sum + a.totalTracks);

    showModalBottomSheet(
      context: context,
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                child: Row(
                  children: [
                    Icon(Icons.download, color: colorScheme.primary),
                    const SizedBox(width: 12),
                    Text(
                      context.l10n.discographyDownload,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Options
              if (albums.isNotEmpty)
                _DiscographyOptionTile(
                  icon: Icons.library_music,
                  title: context.l10n.discographyDownloadAll,
                  subtitle: context.l10n.discographyDownloadAllSubtitle(totalTracks, albums.length),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadAlbums(context, albums);
                  },
                ),
              if (albumsOnly.isNotEmpty)
                _DiscographyOptionTile(
                  icon: Icons.album,
                  title: context.l10n.discographyAlbumsOnly,
                  subtitle: context.l10n.discographyAlbumsOnlySubtitle(albumTracks, albumsOnly.length),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadAlbums(context, albumsOnly);
                  },
                ),
              if (singles.isNotEmpty)
                _DiscographyOptionTile(
                  icon: Icons.music_note,
                  title: context.l10n.discographySinglesOnly,
                  subtitle: context.l10n.discographySinglesOnlySubtitle(singleTracks, singles.length),
                  onTap: () {
                    Navigator.pop(context);
                    _downloadAlbums(context, singles);
                  },
                ),
              _DiscographyOptionTile(
                icon: Icons.checklist,
                title: context.l10n.discographySelectAlbums,
                subtitle: context.l10n.discographySelectAlbumsSubtitle,
                onTap: () {
                  Navigator.pop(context);
                  _enterSelectionMode(albums.first.id);
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadAlbums(BuildContext context, List<ArtistAlbum> albums) async {
    final settings = ref.read(settingsProvider);
    
    if (settings.askQualityBeforeDownload) {
      DownloadServicePicker.show(
        context,
        onSelect: (quality, service) {
          _fetchAndQueueAlbums(albums, service, quality);
        },
      );
    } else {
      _fetchAndQueueAlbums(albums, settings.defaultService, null);
    }
  }

  Future<void> _downloadSelectedAlbums(BuildContext context, List<ArtistAlbum> albums) async {
    _exitSelectionMode();
    await _downloadAlbums(context, albums);
  }

  Future<void> _fetchAndQueueAlbums(
    List<ArtistAlbum> albums,
    String service,
    String? qualityOverride,
  ) async {
    if (_isFetchingDiscography) return;
    
    setState(() => _isFetchingDiscography = true);

    if (!mounted) {
      setState(() => _isFetchingDiscography = false);
      return;
    }
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _FetchingProgressDialog(
        totalAlbums: albums.length,
        onCancel: () {
          setState(() => _isFetchingDiscography = false);
          Navigator.pop(ctx);
        },
      ),
    );

    final allTracks = <Track>[];
    int fetchedCount = 0;
    int failedCount = 0;

    for (final album in albums) {
      if (!_isFetchingDiscography) break; // Cancelled

      try {
        final tracks = await _fetchAlbumTracks(album);
        allTracks.addAll(tracks);
      } catch (e) {
        failedCount++;
      }

      fetchedCount++;
      
      // Update progress dialog
      if (mounted) {
        _FetchingProgressDialog.updateProgress(context, fetchedCount, albums.length);
      }
    }

    setState(() => _isFetchingDiscography = false);

    if (mounted) {
      Navigator.of(context, rootNavigator: true).pop();
    }

    if (failedCount > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.l10n.discographyFailedToFetch)),
      );
    }

    if (allTracks.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.discographyNoAlbums)),
        );
      }
      return;
    }

    // Check which tracks are already downloaded
    final historyState = ref.read(downloadHistoryProvider);
    final tracksToQueue = <Track>[];
    int skippedCount = 0;

    for (final track in allTracks) {
      final isDownloaded = historyState.isDownloaded(track.id) ||
          (track.isrc != null && historyState.getByIsrc(track.isrc!) != null);
      
      if (!isDownloaded) {
        tracksToQueue.add(track);
      } else {
        skippedCount++;
      }
    }

    if (tracksToQueue.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.discographySkippedDownloaded(0, skippedCount)),
          ),
        );
      }
      return;
    }

    ref.read(downloadQueueProvider.notifier).addMultipleToQueue(
      tracksToQueue,
      service,
      qualityOverride: qualityOverride,
    );

    if (mounted) {
      final message = skippedCount > 0
          ? context.l10n.discographySkippedDownloaded(tracksToQueue.length, skippedCount)
          : context.l10n.discographyAddedToQueue(tracksToQueue.length);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          action: SnackBarAction(
            label: context.l10n.snackbarViewQueue,
            onPressed: () {
              // Navigate to queue tab (index 1)
              // This will be handled by the navigation system
            },
          ),
        ),
      );
    }
  }

  Future<List<Track>> _fetchAlbumTracks(ArtistAlbum album) async {
    if (album.providerId != null && album.providerId!.isNotEmpty) {
      final result = await PlatformBridge.getAlbumWithExtension(album.providerId!, album.id);
      if (result != null && result['tracks'] != null) {
        final tracksList = result['tracks'] as List<dynamic>;
        return tracksList.map((t) => _parseTrack(t as Map<String, dynamic>)).toList();
      }
    } else if (album.id.startsWith('deezer:')) {
      final deezerId = album.id.replaceFirst('deezer:', '');
      final metadata = await PlatformBridge.getDeezerMetadata('album', deezerId);
      if (metadata['tracks'] != null) {
        final tracksList = metadata['tracks'] as List<dynamic>;
        return tracksList.map((t) => _parseTrackFromDeezer(t as Map<String, dynamic>, album)).toList();
      }
    } else {
      final url = 'https://open.spotify.com/album/${album.id}';
      final result = await PlatformBridge.handleURLWithExtension(url);
      if (result != null && result['tracks'] != null) {
        final tracksList = result['tracks'] as List<dynamic>;
        return tracksList.map((t) => _parseTrack(t as Map<String, dynamic>)).toList();
      }
      
      // Fallback to direct Spotify metadata
      final metadata = await PlatformBridge.getSpotifyMetadataWithFallback(url);
      if (metadata['tracks'] != null) {
        final tracksList = metadata['tracks'] as List<dynamic>;
        return tracksList.map((t) => _parseTrack(t as Map<String, dynamic>)).toList();
      }
    }
    return [];
  }

  Track _parseTrackFromDeezer(Map<String, dynamic> data, ArtistAlbum album) {
    int durationMs = 0;
    final durationValue = data['duration'];
    if (durationValue is int) {
      durationMs = durationValue * 1000; // Deezer returns seconds
    } else if (durationValue is double) {
      durationMs = (durationValue * 1000).toInt();
    }
    
    return Track(
      id: 'deezer:${data['id']}',
      name: (data['title'] ?? data['name'] ?? '').toString(),
      artistName: (data['artist']?['name'] ?? data['artist'] ?? widget.artistName).toString(),
      albumName: album.name,
      albumArtist: widget.artistName,
      coverUrl: album.coverUrl,
      isrc: data['isrc']?.toString(),
      duration: (durationMs / 1000).round(),
      trackNumber: data['track_position'] as int? ?? data['track_number'] as int?,
      discNumber: data['disk_number'] as int? ?? data['disc_number'] as int?,
      releaseDate: album.releaseDate,
      albumType: album.albumType,
    );
  }

  Widget _buildHeader(BuildContext context, ColorScheme colorScheme, {
    required List<ArtistAlbum> albums,
    required bool hasDiscography,
  }) {
    String? imageUrl = _headerImageUrl;
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = widget.headerImageUrl;
    }
    if (imageUrl == null || imageUrl.isEmpty) {
      imageUrl = widget.coverUrl;
    }
    
    final hasValidImage = imageUrl != null && 
                          imageUrl.isNotEmpty &&
                          Uri.tryParse(imageUrl)?.hasAuthority == true;
    
    String? listenersText;
    final listeners = _monthlyListeners ?? widget.monthlyListeners;
    if (listeners != null && listeners > 0) {
      final formatter = NumberFormat.compact();
      listenersText = context.l10n.artistMonthlyListeners(formatter.format(listeners));
    }
    
return SliverAppBar(
      expandedHeight: hasDiscography ? 420 : 380,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      title: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: _showTitleInAppBar ? 1.0 : 0.0,
        child: Text(
          widget.artistName,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        collapseMode: CollapseMode.none,
        background: Stack(
          fit: StackFit.expand,
          children: [
if (hasValidImage)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter, // Show top of image (faces)
                memCacheWidth: 800,
                cacheManager: CoverCacheManager.instance,
                placeholder: (context, url) => Container(
                  color: colorScheme.surfaceContainerHighest,
                ),
                errorWidget: (context, url, error) => Container(
                  color: colorScheme.surfaceContainerHighest,
                  child: Icon(Icons.person, size: 80, color: colorScheme.onSurfaceVariant),
                ),
              )
            else
              Container(
                color: colorScheme.surfaceContainerHighest,
                child: Icon(Icons.person, size: 80, color: colorScheme.onSurfaceVariant),
              ),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.3),
                    Colors.black.withValues(alpha: 0.7),
                    colorScheme.surface,
                  ],
                  stops: const [0.0, 0.5, 0.75, 1.0],
                ),
              ),
            ),
            Positioned(
              left: 16,
              right: 16,
              bottom: 16,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.artistName,
                    style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          offset: const Offset(0, 1),
                          blurRadius: 4,
                          color: Colors.black.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (listenersText != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      listenersText,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Colors.white.withValues(alpha: 0.8),
                        shadows: [
                          Shadow(
                            offset: const Offset(0, 1),
                            blurRadius: 2,
                            color: Colors.black.withValues(alpha: 0.5),
                          ),
                        ],
                      ),
                    ),
                  ],
                  // Download Discography button
                  if (hasDiscography && !_isSelectionMode) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 40,
                      child: FilledButton.icon(
                        onPressed: () => _showDiscographyOptions(context, colorScheme, albums),
                        icon: const Icon(Icons.download, size: 18),
                        label: Text(context.l10n.discographyDownload),
                        style: FilledButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: Colors.black87,
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
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

  /// Build Popular tracks section like Spotify
  Widget _buildPopularSection(ColorScheme colorScheme) {
    if (_topTracks == null || _topTracks!.isEmpty) return const SizedBox.shrink();
    
    final tracks = _topTracks!.take(5).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            context.l10n.artistPopular,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        ...tracks.asMap().entries.map((entry) {
          final index = entry.key;
          final track = entry.value;
          return _buildPopularTrackItem(index + 1, track, colorScheme);
        }),
      ],
    );
  }

  Widget _buildPopularTrackItem(int rank, Track track, ColorScheme colorScheme) {
    final queueItem = ref.watch(
      downloadQueueLookupProvider.select((lookup) => lookup.byTrackId[track.id]),
    );
    
    final isInHistory = ref.watch(downloadHistoryProvider.select((state) {
      return state.isDownloaded(track.id);
    }));
    
    // Check local library for duplicate detection
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
    
    return InkWell(
      onTap: () => _handlePopularTrackTap(track, isQueued: isQueued, isInHistory: isInHistory, isInLocalLibrary: isInLocalLibrary),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 24,
              child: Text(
                '$rank',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(width: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: track.coverUrl != null
? CachedNetworkImage(
                      imageUrl: track.coverUrl!,
                      width: 48,
                      height: 48,
                      fit: BoxFit.cover,
                      memCacheWidth: 96,
                      cacheManager: CoverCacheManager.instance,
                      placeholder: (context, url) => Container(
                        width: 48,
                        height: 48,
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 48,
                        height: 48,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant, size: 24),
                      ),
                    )
                  : Container(
                      width: 48,
                      height: 48,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant, size: 24),
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    track.name,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (track.albumName.isNotEmpty)
                    Text(
                      track.albumName,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            _buildPopularDownloadButton(
              track: track,
              colorScheme: colorScheme,
              isQueued: isQueued,
              isDownloading: isDownloading,
              isFinalizing: isFinalizing,
              showAsDownloaded: showAsDownloaded,
              isInHistory: isInHistory,
              isInLocalLibrary: isInLocalLibrary,
              progress: progress,
            ),
          ],
        ),
      ),
    );
  }

  /// Handle tap on popular track item
  void _handlePopularTrackTap(Track track, {required bool isQueued, required bool isInHistory, required bool isInLocalLibrary}) async {
    if (isQueued) return;
    
    if (isInLocalLibrary) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.snackbarAlreadyInLibrary(track.name))),
        );
      }
      return;
    }
    
    if (isInHistory) {
      final historyItem = ref.read(downloadHistoryProvider.notifier).getBySpotifyId(track.id);
      if (historyItem != null) {
        final exists = await fileExists(historyItem.filePath);
        if (exists) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(context.l10n.snackbarAlreadyDownloaded(track.name))),
            );
          }
          return;
        } else {
          ref.read(downloadHistoryProvider.notifier).removeBySpotifyId(track.id);
        }
      }
    }
    
    _downloadTrack(track);
  }

  Widget _buildPopularDownloadButton({
    required Track track,
    required ColorScheme colorScheme,
    required bool isQueued,
    required bool isDownloading,
    required bool isFinalizing,
    required bool showAsDownloaded,
    required bool isInHistory,
    required bool isInLocalLibrary,
    required double progress,
  }) {
    const double size = 40.0;
    const double iconSize = 20.0;
    
    if (showAsDownloaded) {
      return GestureDetector(
        onTap: () => _handlePopularTrackTap(track, isQueued: isQueued, isInHistory: isInHistory, isInLocalLibrary: isInLocalLibrary),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.primaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.check, color: colorScheme.onPrimaryContainer, size: iconSize),
        ),
      );
    } else if (isFinalizing) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              strokeWidth: 2.5,
              color: colorScheme.tertiary,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            Icon(Icons.edit_note, color: colorScheme.tertiary, size: 14),
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
            CircularProgressIndicator(
              value: progress > 0 ? progress : null,
              strokeWidth: 2.5,
              color: colorScheme.primary,
              backgroundColor: colorScheme.surfaceContainerHighest,
            ),
            if (progress > 0)
              Text(
                '${(progress * 100).toInt()}',
                style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: colorScheme.primary),
              ),
          ],
        ),
      );
    } else if (isQueued) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.hourglass_empty, color: colorScheme.onSurfaceVariant, size: iconSize),
      );
    } else {
      return GestureDetector(
        onTap: () => _downloadTrack(track),
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: colorScheme.secondaryContainer,
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.download, color: colorScheme.onSecondaryContainer, size: iconSize),
        ),
      );
    }
  }

  void _downloadTrack(Track track) {
    final settings = ref.read(settingsProvider);
    ref.read(settingsProvider.notifier).setHasSearchedBefore();
    ref.read(downloadQueueProvider.notifier).addToQueue(track, settings.defaultService);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(context.l10n.snackbarAddedToQueue(track.name)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildAlbumSection(String title, List<ArtistAlbum> albums, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 24, 16, 12),
          child: Text(
            '$title (${albums.length})',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return KeyedSubtree(
                key: ValueKey(album.id),
                child: _buildAlbumCard(album, colorScheme),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAlbumCard(ArtistAlbum album, ColorScheme colorScheme) {
    final isSelected = _selectedAlbumIds.contains(album.id);
    
    return GestureDetector(
      onTap: () {
        if (_isSelectionMode) {
          _toggleAlbumSelection(album.id);
        } else {
          _navigateToAlbum(album);
        }
      },
      onLongPress: () {
        if (!_isSelectionMode) {
          _enterSelectionMode(album.id);
        }
      },
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: album.coverUrl != null
? CachedNetworkImage(
                      imageUrl: album.coverUrl!,
                      width: 140,
                      height: 140,
                      fit: BoxFit.cover,
                      memCacheWidth: 280,
                      cacheManager: CoverCacheManager.instance,
                      placeholder: (context, url) => Container(
                        width: 140,
                        height: 140,
                        color: colorScheme.surfaceContainerHighest,
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 140,
                        height: 140,
                        color: colorScheme.surfaceContainerHighest,
                        child: Icon(Icons.album, color: colorScheme.onSurfaceVariant, size: 40),
                      ),
                    )
                  : Container(
                      width: 140,
                      height: 140,
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(Icons.album, color: colorScheme.onSurfaceVariant, size: 40),
                    ),
            ),
                // Selection overlay
                if (_isSelectionMode)
                  Positioned.fill(
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        color: isSelected 
                            ? colorScheme.primary.withValues(alpha: 0.3)
                            : Colors.black.withValues(alpha: 0.1),
                        border: isSelected 
                            ? Border.all(color: colorScheme.primary, width: 3)
                            : null,
                      ),
                    ),
                  ),
                // Checkbox
                if (_isSelectionMode)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isSelected 
                            ? colorScheme.primary 
                            : colorScheme.surface.withValues(alpha: 0.9),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected 
                              ? colorScheme.primary 
                              : colorScheme.outline,
                          width: 2,
                        ),
                      ),
                      child: isSelected
                          ? Icon(Icons.check, color: colorScheme.onPrimary, size: 18)
                          : null,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              album.name,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              album.totalTracks > 0 
                  ? '${album.releaseDate.length >= 4 ? album.releaseDate.substring(0, 4) : album.releaseDate} ${context.l10n.tracksCount(album.totalTracks)}'
                  : album.releaseDate.length >= 4 ? album.releaseDate.substring(0, 4) : album.releaseDate,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _navigateToAlbum(ArtistAlbum album) {
    ref.read(settingsProvider.notifier).setHasSearchedBefore();
    
    if (album.providerId != null && album.providerId!.isNotEmpty) {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => ExtensionAlbumScreen(
          extensionId: album.providerId!,
          albumId: album.id,
          albumName: album.name,
          coverUrl: album.coverUrl,
        ),
      ));
    } else {
      Navigator.push(context, MaterialPageRoute(
        builder: (context) => AlbumScreen(
          albumId: album.id,
          albumName: album.name,
          coverUrl: album.coverUrl,
        ),
      ));
    }
  }

  Widget _buildErrorWidget(String error, ColorScheme colorScheme) {
    final isRateLimit = error.contains('429') || 
                        error.toLowerCase().contains('rate limit') ||
                        error.toLowerCase().contains('too many requests');
    
    if (isRateLimit) {
      return Card(
        elevation: 0,
        color: colorScheme.errorContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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

/// Option tile for discography download bottom sheet
class _DiscographyOptionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _DiscographyOptionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 24),
      ),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(
        subtitle, 
        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
      ),
      trailing: Icon(Icons.chevron_right, color: colorScheme.onSurfaceVariant),
      onTap: onTap,
    );
  }
}

/// Progress dialog shown while fetching album tracks
class _FetchingProgressDialog extends StatefulWidget {
  final int totalAlbums;
  final VoidCallback onCancel;

  const _FetchingProgressDialog({
    required this.totalAlbums,
    required this.onCancel,
  });

  // Static method to update progress from outside
  static void updateProgress(BuildContext context, int current, int total) {
    final state = context.findAncestorStateOfType<_FetchingProgressDialogState>();
    state?._updateProgress(current, total);
  }

  @override
  State<_FetchingProgressDialog> createState() => _FetchingProgressDialogState();
}

class _FetchingProgressDialogState extends State<_FetchingProgressDialog> {
  int _current = 0;
  int _total = 0;

  @override
  void initState() {
    super.initState();
    _total = widget.totalAlbums;
  }

  void _updateProgress(int current, int total) {
    if (mounted) {
      setState(() {
        _current = current;
        _total = total;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final progress = _total > 0 ? _current / _total : 0.0;

    return AlertDialog(
      backgroundColor: colorScheme.surfaceContainerHigh,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 8),
          SizedBox(
            width: 64,
            height: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress > 0 ? progress : null,
                  strokeWidth: 4,
                  backgroundColor: colorScheme.surfaceContainerHighest,
                ),
                Icon(Icons.library_music, color: colorScheme.primary, size: 24),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Text(
            context.l10n.discographyFetchingTracks,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.l10n.discographyFetchingAlbum(_current, _total),
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress > 0 ? progress : null,
              backgroundColor: colorScheme.surfaceContainerHighest,
              minHeight: 6,
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: widget.onCancel,
          child: Text(context.l10n.dialogCancel),
        ),
      ],
    );
  }
}
