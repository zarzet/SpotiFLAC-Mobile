import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';

/// Screen to display detailed metadata for a downloaded track
/// Designed with Material Expressive 3 style
class TrackMetadataScreen extends ConsumerStatefulWidget {
  final DownloadHistoryItem item;

  const TrackMetadataScreen({super.key, required this.item});

  @override
  ConsumerState<TrackMetadataScreen> createState() => _TrackMetadataScreenState();
}

class _TrackMetadataScreenState extends ConsumerState<TrackMetadataScreen> {
  bool _fileExists = false;
  int? _fileSize;
  String? _lyrics;
  bool _lyricsLoading = false;
  String? _lyricsError;

  @override
  void initState() {
    super.initState();
    _checkFile();
  }

  Future<void> _checkFile() async {
    final file = File(widget.item.filePath);
    final exists = await file.exists();
    int? size;
    if (exists) {
      try {
        size = await file.length();
      } catch (_) {}
    }
    if (mounted) {
      setState(() {
        _fileExists = exists;
        _fileSize = size;
      });
    }
  }

  DownloadHistoryItem get item => widget.item;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // App Bar with cover art background
          SliverAppBar(
            expandedHeight: 280,
            pinned: true,
            stretch: true,
            backgroundColor: colorScheme.surface,
            flexibleSpace: FlexibleSpaceBar(
              background: _buildHeaderBackground(context, colorScheme),
              stretchModes: const [
                StretchMode.zoomBackground,
                StretchMode.blurBackground,
              ],
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
            actions: [
              IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colorScheme.surface.withValues(alpha: 0.8),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.more_vert, color: colorScheme.onSurface),
                ),
                onPressed: () => _showOptionsMenu(context, ref, colorScheme),
              ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Track info card
                  _buildTrackInfoCard(context, colorScheme, _fileExists),
                  
                  const SizedBox(height: 16),
                  
                  // Metadata card
                  _buildMetadataCard(context, colorScheme, _fileSize),
                  
                  const SizedBox(height: 16),
                  
                  // File info card
                  _buildFileInfoCard(context, colorScheme, _fileExists, _fileSize),
                  
                  const SizedBox(height: 16),
                  
                  // Lyrics card
                  _buildLyricsCard(context, colorScheme),
                  
                  const SizedBox(height: 24),
                  
                  // Action buttons
                  _buildActionButtons(context, ref, colorScheme, _fileExists),
                  
                  const SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderBackground(BuildContext context, ColorScheme colorScheme) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Blurred background
        if (item.coverUrl != null)
          CachedNetworkImage(
            imageUrl: item.coverUrl!,
            fit: BoxFit.cover,
            color: Colors.black.withValues(alpha: 0.5),
            colorBlendMode: BlendMode.darken,
          ),
        
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.transparent,
                colorScheme.surface.withValues(alpha: 0.8),
                colorScheme.surface,
              ],
              stops: const [0.0, 0.7, 1.0],
            ),
          ),
        ),
        
        // Cover art centered
        Center(
          child: Padding(
            padding: const EdgeInsets.only(top: 60),
            child: Hero(
              tag: 'cover_${item.id}',
              child: Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: item.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: item.coverUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(
                              Icons.music_note,
                              size: 48,
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Icon(
                            Icons.music_note,
                            size: 48,
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTrackInfoCard(BuildContext context, ColorScheme colorScheme, bool fileExists) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Track name
            Text(
              item.trackName,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 4),
            
            // Artist name
            Text(
              item.artistName,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: colorScheme.primary,
              ),
            ),
            const SizedBox(height: 8),
            
            // Album name
            Row(
              children: [
                Icon(
                  Icons.album,
                  size: 16,
                  color: colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    item.albumName,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
            
            // File status
            if (!fileExists) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_rounded,
                      size: 16,
                      color: colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'File not found',
                      style: TextStyle(
                        color: colorScheme.onErrorContainer,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetadataCard(BuildContext context, ColorScheme colorScheme, int? fileSize) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Metadata',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Metadata grid
            _buildMetadataGrid(context, colorScheme),
            
            // Spotify link button
            if (item.spotifyId != null && item.spotifyId!.isNotEmpty) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => _openSpotifyUrl(context),
                icon: const Icon(Icons.open_in_new, size: 18),
                label: const Text('Open in Spotify'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _openSpotifyUrl(BuildContext context) async {
    if (item.spotifyId == null) return;
    
    final url = 'https://open.spotify.com/track/${item.spotifyId}';
    try {
      // Try to open in Spotify app first, fallback to browser
      final uri = Uri.parse('spotify:track:${item.spotifyId}');
      // ignore: deprecated_member_use
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      if (context.mounted) {
        _copyToClipboard(context, url);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Spotify URL copied to clipboard')),
        );
      }
    }
  }

  Widget _buildMetadataGrid(BuildContext context, ColorScheme colorScheme) {
    final items = <_MetadataItem>[
      _MetadataItem('Track name', item.trackName),
      _MetadataItem('Artist', item.artistName),
      if (item.albumArtist != null && item.albumArtist != item.artistName)
        _MetadataItem('Album artist', item.albumArtist!),
      _MetadataItem('Album', item.albumName),
      if (item.trackNumber != null)
        _MetadataItem('Track number', item.trackNumber.toString()),
      if (item.discNumber != null && item.discNumber! > 1)
        _MetadataItem('Disc number', item.discNumber.toString()),
      if (item.duration != null)
        _MetadataItem('Duration', _formatDuration(item.duration!)),
      if (item.releaseDate != null && item.releaseDate!.isNotEmpty)
        _MetadataItem('Release date', item.releaseDate!),
      if (item.isrc != null && item.isrc!.isNotEmpty)
        _MetadataItem('ISRC', item.isrc!),
      if (item.spotifyId != null && item.spotifyId!.isNotEmpty)
        _MetadataItem('Spotify ID', item.spotifyId!),
      if (item.quality != null && item.quality!.isNotEmpty)
        _MetadataItem('Quality', _formatQuality(item.quality!)),
      _MetadataItem('Service', item.service.toUpperCase()),
      _MetadataItem('Downloaded', _formatFullDate(item.downloadedAt)),
    ];

    return Column(
      children: items.map((metadata) {
        final isCopyable = metadata.label == 'ISRC' || 
                          metadata.label == 'Spotify ID';
        return InkWell(
          onTap: isCopyable ? () => _copyToClipboard(context, metadata.value) : null,
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 100,
                  child: Text(
                    metadata.label,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    metadata.value,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
                if (isCopyable)
                  Icon(
                    Icons.copy,
                    size: 14,
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
                  ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  String _formatQuality(String quality) {
    switch (quality) {
      case 'LOSSLESS':
        return 'Lossless (16-bit)';
      case 'HI_RES':
        return 'Hi-Res (24-bit)';
      case 'HI_RES_LOSSLESS':
        return 'Hi-Res Lossless (24-bit)';
      default:
        return quality;
    }
  }

  String _formatQualityShort(String quality) {
    switch (quality) {
      case 'LOSSLESS':
        return '16-bit';
      case 'HI_RES':
        return '24-bit';
      case 'HI_RES_LOSSLESS':
        return 'Hi-Res';
      default:
        return quality;
    }
  }

  Widget _buildFileInfoCard(BuildContext context, ColorScheme colorScheme, bool fileExists, int? fileSize) {
    final fileName = item.filePath.split(Platform.pathSeparator).last;
    final fileExtension = fileName.contains('.') ? fileName.split('.').last.toUpperCase() : 'Unknown';
    
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.folder_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'File Info',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Format chip
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: colorScheme.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    fileExtension,
                    style: TextStyle(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
                if (fileSize != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.secondaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatFileSize(fileSize),
                      style: TextStyle(
                        color: colorScheme.onSecondaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                if (item.quality != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      _formatQualityShort(item.quality!),
                      style: TextStyle(
                        color: colorScheme.onTertiaryContainer,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _getServiceColor(item.service, colorScheme),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _getServiceIcon(item.service),
                        size: 14,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        item.service.toUpperCase(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // File path
            InkWell(
              onTap: () => _copyToClipboard(context, item.filePath),
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.filePath,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontFamily: 'monospace',
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.copy,
                      size: 18,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLyricsCard(BuildContext context, ColorScheme colorScheme) {
    return Card(
      elevation: 0,
      color: colorScheme.surfaceContainerLow,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.lyrics_outlined,
                  size: 20,
                  color: colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Lyrics',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                if (_lyrics != null)
                  IconButton(
                    icon: const Icon(Icons.copy, size: 20),
                    onPressed: () => _copyToClipboard(context, _lyrics!),
                    tooltip: 'Copy lyrics',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            
            if (_lyricsLoading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_lyricsError != null)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.errorContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: colorScheme.error, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _lyricsError!,
                        style: TextStyle(color: colorScheme.onErrorContainer),
                      ),
                    ),
                    TextButton(
                      onPressed: _fetchLyrics,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              )
            else if (_lyrics != null)
              Container(
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Text(
                    _lyrics!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurface,
                      height: 1.6,
                    ),
                  ),
                ),
              )
            else
              Center(
                child: FilledButton.tonalIcon(
                  onPressed: _fetchLyrics,
                  icon: const Icon(Icons.download),
                  label: const Text('Load Lyrics'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _fetchLyrics() async {
    if (_lyricsLoading) return;
    
    setState(() {
      _lyricsLoading = true;
      _lyricsError = null;
    });

    try {
      final result = await PlatformBridge.getLyricsLRC(
        item.spotifyId ?? '',
        item.trackName,
        item.artistName,
      );
      
      if (mounted) {
        if (result.isEmpty) {
          setState(() {
            _lyricsError = 'Lyrics not found';
            _lyricsLoading = false;
          });
        } else {
          // Clean up LRC timestamps for display
          final cleanLyrics = _cleanLrcForDisplay(result);
          setState(() {
            _lyrics = cleanLyrics;
            _lyricsLoading = false;
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _lyricsError = 'Failed to load lyrics';
          _lyricsLoading = false;
        });
      }
    }
  }

  String _cleanLrcForDisplay(String lrc) {
    // Remove LRC timestamps [mm:ss.xx] for cleaner display
    final lines = lrc.split('\n');
    final cleanLines = <String>[];
    final timestampPattern = RegExp(r'^\[\d{2}:\d{2}\.\d{2,3}\]');
    
    for (final line in lines) {
      final cleanLine = line.replaceAll(timestampPattern, '').trim();
      if (cleanLine.isNotEmpty) {
        cleanLines.add(cleanLine);
      }
    }
    
    return cleanLines.join('\n');
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, ColorScheme colorScheme, bool fileExists) {
    return Row(
      children: [
        // Play button
        Expanded(
          flex: 2,
          child: FilledButton.icon(
            onPressed: fileExists ? () => _openFile(context, item.filePath) : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        
        // Delete button
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _confirmDelete(context, ref, colorScheme),
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            label: Text('Delete', style: TextStyle(color: colorScheme.error)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              side: BorderSide(color: colorScheme.error.withValues(alpha: 0.5)),
            ),
          ),
        ),
      ],
    );
  }

  void _showOptionsMenu(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.copy),
              title: const Text('Copy file path'),
              onTap: () {
                Navigator.pop(context);
                _copyToClipboard(context, item.filePath);
              },
            ),
            ListTile(
              leading: const Icon(Icons.share),
              title: const Text('Share'),
              onTap: () {
                Navigator.pop(context);
                // TODO: Implement share
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: colorScheme.error),
              title: Text('Remove from history', style: TextStyle(color: colorScheme.error)),
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(context, ref, colorScheme);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, ColorScheme colorScheme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove from history?'),
        content: const Text(
          'This will remove the track from your download history. '
          'The downloaded file will not be deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(downloadHistoryProvider.notifier).removeFromHistory(item.id);
              Navigator.pop(context); // Close dialog
              Navigator.pop(context); // Go back to history
            },
            child: Text('Remove', style: TextStyle(color: colorScheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _openFile(BuildContext context, String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      if (result.type != ResultType.done && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open: ${result.message}')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open file: $e')),
        );
      }
    }
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  String _formatFullDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 
                    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${date.day} ${months[date.month - 1]} ${date.year}, '
           '${date.hour.toString().padLeft(2, '0')}:'
           '${date.minute.toString().padLeft(2, '0')}';
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
  }

  IconData _getServiceIcon(String service) {
    switch (service.toLowerCase()) {
      case 'tidal':
        return Icons.waves;
      case 'qobuz':
        return Icons.album;
      case 'amazon':
        return Icons.shopping_cart;
      default:
        return Icons.cloud_download;
    }
  }

  Color _getServiceColor(String service, ColorScheme colorScheme) {
    switch (service.toLowerCase()) {
      case 'tidal':
        return const Color(0xFF0077B5); // Tidal blue (darker, more readable)
      case 'qobuz':
        return const Color(0xFF0052CC); // Qobuz blue
      case 'amazon':
        return const Color(0xFFFF9900); // Amazon orange
      default:
        return colorScheme.primary;
    }
  }
}

class _MetadataItem {
  final String label;
  final String value;
  
  _MetadataItem(this.label, this.value);
}
