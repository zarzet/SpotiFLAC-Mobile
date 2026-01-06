import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/providers/track_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/screens/album_screen.dart';

/// Simple in-memory cache for artist discography
class _ArtistCache {
  static final Map<String, _CacheEntry> _cache = {};
  static const Duration _ttl = Duration(minutes: 10);

  static List<ArtistAlbum>? get(String artistId) {
    final entry = _cache[artistId];
    if (entry == null) return null;
    if (DateTime.now().isAfter(entry.expiresAt)) {
      _cache.remove(artistId);
      return null;
    }
    return entry.albums;
  }

  static void set(String artistId, List<ArtistAlbum> albums) {
    _cache[artistId] = _CacheEntry(albums, DateTime.now().add(_ttl));
  }
}

class _CacheEntry {
  final List<ArtistAlbum> albums;
  final DateTime expiresAt;
  _CacheEntry(this.albums, this.expiresAt);
}

/// Artist screen with Material Expressive 3 design - shows discography
class ArtistScreen extends ConsumerStatefulWidget {
  final String artistId;
  final String artistName;
  final String? coverUrl;
  final List<ArtistAlbum>? albums; // Optional - will fetch if null

  const ArtistScreen({
    super.key,
    required this.artistId,
    required this.artistName,
    this.coverUrl,
    this.albums,
  });

  @override
  ConsumerState<ArtistScreen> createState() => _ArtistScreenState();
}

class _ArtistScreenState extends ConsumerState<ArtistScreen> {
  bool _isLoadingDiscography = false;
  List<ArtistAlbum>? _albums;
  String? _error;

  @override
  void initState() {
    super.initState();
    // Priority: widget.albums > cache > fetch
    _albums = widget.albums ?? _ArtistCache.get(widget.artistId);
    if (_albums == null) {
      _fetchDiscography();
    }
  }

  Future<void> _fetchDiscography() async {
    setState(() => _isLoadingDiscography = true);
    try {
      List<ArtistAlbum> albums;
      
      // Check if this is a Deezer artist ID (format: "deezer:123456")
      if (widget.artistId.startsWith('deezer:')) {
        final deezerArtistId = widget.artistId.replaceFirst('deezer:', '');
        // ignore: avoid_print
        print('[ArtistScreen] Fetching from Deezer: $deezerArtistId');
        final metadata = await PlatformBridge.getDeezerMetadata('artist', deezerArtistId);
        final albumsList = metadata['albums'] as List<dynamic>;
        albums = albumsList.map((a) => _parseArtistAlbum(a as Map<String, dynamic>)).toList();
      } else {
        // Spotify artist - use fallback method
        // ignore: avoid_print
        print('[ArtistScreen] Fetching from Spotify with fallback: ${widget.artistId}');
        final url = 'https://open.spotify.com/artist/${widget.artistId}';
        final metadata = await PlatformBridge.getSpotifyMetadataWithFallback(url);
        final albumsList = metadata['albums'] as List<dynamic>;
        albums = albumsList.map((a) => _parseArtistAlbum(a as Map<String, dynamic>)).toList();
      }
      
      // Store in cache
      _ArtistCache.set(widget.artistId, albums);
      
      if (mounted) {
        setState(() {
          _albums = albums;
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

  ArtistAlbum _parseArtistAlbum(Map<String, dynamic> data) {
    return ArtistAlbum(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      releaseDate: data['release_date'] as String? ?? '',
      totalTracks: data['total_tracks'] as int? ?? 0,
      coverUrl: data['images'] as String?,
      albumType: data['album_type'] as String? ?? 'album',
      artists: data['artists'] as String? ?? '',
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
      body: Stack(
        children: [
          CustomScrollView(
            slivers: [
              _buildAppBar(context, colorScheme),
              _buildInfoCard(context, colorScheme),
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
                if (albumsOnly.isNotEmpty) SliverToBoxAdapter(child: _buildAlbumSection('Albums', albumsOnly, colorScheme)),
                if (singles.isNotEmpty) SliverToBoxAdapter(child: _buildAlbumSection('Singles & EPs', singles, colorScheme)),
                if (compilations.isNotEmpty) SliverToBoxAdapter(child: _buildAlbumSection('Compilations', compilations, colorScheme)),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar(BuildContext context, ColorScheme colorScheme) {
    return SliverAppBar(
      expandedHeight: 280,
      pinned: true,
      stretch: true,
      backgroundColor: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.coverUrl != null)
              CachedNetworkImage(imageUrl: widget.coverUrl!, fit: BoxFit.cover, color: Colors.black.withValues(alpha: 0.5), colorBlendMode: BlendMode.darken, memCacheWidth: 600),
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, colorScheme.surface.withValues(alpha: 0.8), colorScheme.surface],
                  stops: const [0.0, 0.7, 1.0],
                ),
              ),
            ),
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
                child: Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: ClipOval(
                    child: widget.coverUrl != null
                        ? CachedNetworkImage(imageUrl: widget.coverUrl!, fit: BoxFit.cover, memCacheWidth: 280)
                        : Container(color: colorScheme.surfaceContainerHighest, child: Icon(Icons.person, size: 48, color: colorScheme.onSurfaceVariant)),
                  ),
                ),
              ),
            ),
          ],
        ),
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
      ),
      leading: IconButton(
        icon: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: colorScheme.surface.withValues(alpha: 0.8), shape: BoxShape.circle), child: Icon(Icons.arrow_back, color: colorScheme.onSurface)),
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
                Text(widget.artistName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface)),
                const SizedBox(height: 8),
                if (_albums != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.album, size: 14, color: colorScheme.onPrimaryContainer),
                        const SizedBox(width: 4),
                        Text('${_albums!.length} releases', style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600, fontSize: 12)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAlbumSection(String title, List<ArtistAlbum> albums, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Icon(Icons.album, size: 20, color: colorScheme.primary),
              const SizedBox(width: 8),
              Text('$title (${albums.length})', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.primary)),
            ],
          ),
        ),
        SizedBox(
          height: 210,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            itemCount: albums.length,
            itemBuilder: (context, index) {
              final album = albums[index];
              return KeyedSubtree(key: ValueKey(album.id), child: _buildAlbumCard(album, colorScheme));
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
        margin: const EdgeInsets.symmetric(horizontal: 6),
        child: Card(
          elevation: 0,
          color: colorScheme.surfaceContainerLow,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: album.coverUrl != null
                      ? CachedNetworkImage(imageUrl: album.coverUrl!, width: 124, height: 124, fit: BoxFit.cover, memCacheWidth: 248)
                      : Container(width: 124, height: 124, color: colorScheme.surfaceContainerHighest, child: Icon(Icons.album, color: colorScheme.onSurfaceVariant, size: 40)),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(album.name, style: Theme.of(context).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
                      const Spacer(),
                      Text(
                        album.totalTracks > 0 
                            ? '${album.releaseDate.length >= 4 ? album.releaseDate.substring(0, 4) : album.releaseDate} • ${album.totalTracks} tracks'
                            : album.releaseDate.length >= 4 ? album.releaseDate.substring(0, 4) : album.releaseDate,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant, fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _navigateToAlbum(ArtistAlbum album) {
    // Navigate immediately with data from artist discography, fetch tracks in AlbumScreen
    ref.read(settingsProvider.notifier).setHasSearchedBefore();
    Navigator.push(context, MaterialPageRoute(
      builder: (context) => AlbumScreen(
        albumId: album.id,
        albumName: album.name,
        coverUrl: album.coverUrl,
        // tracks: null - will be fetched in AlbumScreen
      ),
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
                      'Too many requests. Please wait a moment and try again.',
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
}
