import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/providers/track_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/recent_access_provider.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/screens/album_screen.dart';
import 'package:spotiflac_android/screens/home_tab.dart' show ExtensionAlbumScreen;

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
  final String? extensionId; // If set, skip fetching from Spotify/Deezer

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

  @override
  void initState() {
    super.initState();
    
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

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _buildHeader(context, colorScheme),
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
          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }

  /// Build Spotify-style header with full-width image and artist name overlay
  Widget _buildHeader(BuildContext context, ColorScheme colorScheme) {
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
      expandedHeight: 380,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (hasValidImage)
              CachedNetworkImage(
                imageUrl: imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter, // Show top of image (faces)
                memCacheWidth: 800,
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

  /// Build a single popular track item with dynamic download status
  Widget _buildPopularTrackItem(int rank, Track track, ColorScheme colorScheme) {
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
    
    return InkWell(
      onTap: () => _handlePopularTrackTap(track, isQueued: isQueued, isInHistory: isInHistory),
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
              progress: progress,
            ),
          ],
        ),
      ),
    );
  }

  /// Handle tap on popular track item
  void _handlePopularTrackTap(Track track, {required bool isQueued, required bool isInHistory}) async {
    if (isQueued) return;
    
    if (isInHistory) {
      final historyItem = ref.read(downloadHistoryProvider.notifier).getBySpotifyId(track.id);
      if (historyItem != null) {
        final fileExists = await File(historyItem.filePath).exists();
        if (fileExists) {
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

  /// Build download button with status indicator for popular tracks
  Widget _buildPopularDownloadButton({
    required Track track,
    required ColorScheme colorScheme,
    required bool isQueued,
    required bool isDownloading,
    required bool isFinalizing,
    required bool showAsDownloaded,
    required bool isInHistory,
    required double progress,
  }) {
    const double size = 40.0;
    const double iconSize = 20.0;
    
    if (showAsDownloaded) {
      return GestureDetector(
        onTap: () => _handlePopularTrackTap(track, isQueued: isQueued, isInHistory: isInHistory),
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
    return GestureDetector(
      onTap: () => _navigateToAlbum(album),
      child: Container(
        width: 140,
        margin: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
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
