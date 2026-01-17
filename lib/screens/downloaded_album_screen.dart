import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/utils/mime_utils.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/screens/track_metadata_screen.dart';

/// Screen to display downloaded tracks from a specific album
class DownloadedAlbumScreen extends ConsumerStatefulWidget {
  final String albumName;
  final String artistName;
  final String? coverUrl;

  const DownloadedAlbumScreen({
    super.key,
    required this.albumName,
    required this.artistName,
    this.coverUrl,
  });

  @override
  ConsumerState<DownloadedAlbumScreen> createState() => _DownloadedAlbumScreenState();
}

class _DownloadedAlbumScreenState extends ConsumerState<DownloadedAlbumScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  /// Get tracks for this album from history provider (reactive)
  List<DownloadHistoryItem> _getAlbumTracks(List<DownloadHistoryItem> allItems) {
    return allItems.where((item) {
      final itemKey = '${item.albumName}|${item.albumArtist ?? item.artistName}';
      final albumKey = '${widget.albumName}|${widget.artistName}';
      return itemKey == albumKey;
    }).toList()
      ..sort((a, b) {
        final aNum = a.trackNumber ?? 999;
        final bNum = b.trackNumber ?? 999;
        if (aNum != bNum) return aNum.compareTo(bNum);
        return a.trackName.compareTo(b.trackName);
      });
  }

  void _enterSelectionMode(String itemId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(itemId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  void _toggleSelection(String itemId) {
    setState(() {
      if (_selectedIds.contains(itemId)) {
        _selectedIds.remove(itemId);
        if (_selectedIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedIds.add(itemId);
      }
    });
  }

  void _selectAll(List<DownloadHistoryItem> tracks) {
    setState(() {
      _selectedIds.addAll(tracks.map((e) => e.id));
    });
  }

  Future<void> _deleteSelected(List<DownloadHistoryItem> currentTracks) async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.downloadedAlbumDeleteSelected),
        content: Text(context.l10n.downloadedAlbumDeleteMessage(count)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(context.l10n.dialogDelete),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final historyNotifier = ref.read(downloadHistoryProvider.notifier);
      final idsToDelete = _selectedIds.toList();
      
      int deletedCount = 0;
      for (final id in idsToDelete) {
        final item = currentTracks.where((e) => e.id == id).firstOrNull;
        if (item != null) {
          try {
            final file = File(item.filePath);
            if (await file.exists()) {
              await file.delete();
            }
          } catch (_) {}
          historyNotifier.removeFromHistory(id);
          deletedCount++;
        }
      }
      
      _exitSelectionMode();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.snackbarDeletedTracks(deletedCount))),
        );
      }
    }
  }

  Future<void> _openFile(String filePath) async {
    try {
      final mimeType = audioMimeTypeForPath(filePath);
      await OpenFilex.open(filePath, type: mimeType);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.snackbarCannotOpenFile(e.toString()))),
        );
      }
    }
  }

  void _navigateToMetadataScreen(DownloadHistoryItem item) {
    Navigator.push(context, PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 300),
      reverseTransitionDuration: const Duration(milliseconds: 250),
      pageBuilder: (context, animation, secondaryAnimation) => TrackMetadataScreen(item: item),
      transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    
    final allHistoryItems = ref.watch(downloadHistoryProvider.select((s) => s.items));
    final tracks = _getAlbumTracks(allHistoryItems);
    
    if (tracks.length < 2) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
      return const SizedBox.shrink();
    }
    
    final validIds = tracks.map((t) => t.id).toSet();
    _selectedIds.removeWhere((id) => !validIds.contains(id));
    if (_selectedIds.isEmpty && _isSelectionMode) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _isSelectionMode = false);
      });
    }

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
              slivers: [
                _buildAppBar(context, colorScheme),
                _buildInfoCard(context, colorScheme, tracks),
                _buildTrackListHeader(context, colorScheme, tracks),
                _buildTrackList(context, colorScheme, tracks),
                SliverToBoxAdapter(child: SizedBox(height: _isSelectionMode ? 120 : 32)),
              ],
            ),
            
            AnimatedPositioned(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              left: 0,
              right: 0,
              bottom: _isSelectionMode ? 0 : -(200 + bottomPadding),
              child: _buildSelectionBottomBar(context, colorScheme, tracks, bottomPadding),
            ),
          ],
        ),
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
              CachedNetworkImage(
                imageUrl: widget.coverUrl!,
                fit: BoxFit.cover,
                color: Colors.black.withValues(alpha: 0.5),
                colorBlendMode: BlendMode.darken,
                memCacheWidth: 600,
              ),
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
            Center(
              child: Padding(
                padding: const EdgeInsets.only(top: 60),
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
                    child: widget.coverUrl != null
                        ? CachedNetworkImage(imageUrl: widget.coverUrl!, fit: BoxFit.cover, memCacheWidth: 280)
                        : Container(
                            color: colorScheme.surfaceContainerHighest,
                            child: Icon(Icons.album, size: 48, color: colorScheme.onSurfaceVariant),
                          ),
                  ),
                ),
              ),
            ),
          ],
        ),
        stretchModes: const [StretchMode.zoomBackground, StretchMode.blurBackground],
      ),
      leading: IconButton(
        icon: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: colorScheme.surface.withValues(alpha: 0.8), shape: BoxShape.circle),
          child: Icon(Icons.arrow_back, color: colorScheme.onSurface),
        ),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context, ColorScheme colorScheme, List<DownloadHistoryItem> tracks) {
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
                Text(
                  widget.albumName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.onSurface),
                ),
                const SizedBox(height: 4),
                Text(
                  widget.artistName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: colorScheme.onSurfaceVariant),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: colorScheme.primaryContainer, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.download_done, size: 14, color: colorScheme.onPrimaryContainer),
                          const SizedBox(width: 4),
                          Text(context.l10n.downloadedAlbumDownloadedCount(tracks.length), style: TextStyle(color: colorScheme.onPrimaryContainer, fontWeight: FontWeight.w600, fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_getCommonQuality(tracks) != null)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _getCommonQuality(tracks)!.startsWith('24') 
                              ? colorScheme.tertiaryContainer 
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          _getCommonQuality(tracks)!,
                          style: TextStyle(
                            color: _getCommonQuality(tracks)!.startsWith('24') 
                                ? colorScheme.onTertiaryContainer 
                                : colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _getCommonQuality(List<DownloadHistoryItem> tracks) {
    if (tracks.isEmpty) return null;
    final firstQuality = tracks.first.quality;
    if (firstQuality == null) return null;
    for (final track in tracks) {
      if (track.quality != firstQuality) return null;
    }
    return firstQuality;
  }

  Widget _buildTrackListHeader(BuildContext context, ColorScheme colorScheme, List<DownloadHistoryItem> tracks) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 8),
        child: Row(
          children: [
            Icon(Icons.queue_music, size: 20, color: colorScheme.primary),
            const SizedBox(width: 8),
            Text(context.l10n.downloadedAlbumTracksHeader, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600, color: colorScheme.onSurface)),
            const Spacer(),
            if (!_isSelectionMode)
              TextButton.icon(
                onPressed: tracks.isNotEmpty ? () => _enterSelectionMode(tracks.first.id) : null,
                icon: const Icon(Icons.checklist, size: 18),
                label: Text(context.l10n.actionSelect),
                style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackList(BuildContext context, ColorScheme colorScheme, List<DownloadHistoryItem> tracks) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final track = tracks[index];
          return KeyedSubtree(
            key: ValueKey(track.id),
            child: _buildTrackItem(context, colorScheme, track),
          );
        },
        childCount: tracks.length,
      ),
    );
  }

  Widget _buildTrackItem(BuildContext context, ColorScheme colorScheme, DownloadHistoryItem track) {
    final isSelected = _selectedIds.contains(track.id);
    
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Card(
        elevation: 0,
        color: isSelected ? colorScheme.primaryContainer.withValues(alpha: 0.3) : Colors.transparent,
        margin: const EdgeInsets.symmetric(vertical: 2),
        child: ListTile(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          onTap: _isSelectionMode 
              ? () => _toggleSelection(track.id)
              : () => _navigateToMetadataScreen(track),
          onLongPress: _isSelectionMode ? null : () => _enterSelectionMode(track.id),
          leading: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_isSelectionMode) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected ? colorScheme.primary : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? colorScheme.primary : colorScheme.outline, width: 2),
                  ),
                  child: isSelected 
                      ? Icon(Icons.check, color: colorScheme.onPrimary, size: 16)
                      : null,
                ),
                const SizedBox(width: 12),
              ],
              SizedBox(
                width: 24,
                child: Text(
                  track.trackNumber?.toString() ?? '-',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          title: Text(
            track.trackName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500),
          ),
          subtitle: Text(
            track.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(color: colorScheme.onSurfaceVariant),
          ),
          trailing: _isSelectionMode ? null : IconButton(
            onPressed: () => _openFile(track.filePath),
            icon: Icon(Icons.play_arrow, color: colorScheme.primary),
            style: IconButton.styleFrom(
              backgroundColor: colorScheme.primaryContainer.withValues(alpha: 0.3),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectionBottomBar(BuildContext context, ColorScheme colorScheme, List<DownloadHistoryItem> tracks, double bottomPadding) {
    final selectedCount = _selectedIds.length;
    final allSelected = selectedCount == tracks.length && tracks.isNotEmpty;
    
    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHigh,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(16, 16, 16, bottomPadding > 0 ? 8 : 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Row(
                children: [
                  IconButton.filledTonal(
                    onPressed: _exitSelectionMode,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          context.l10n.downloadedAlbumSelectedCount(selectedCount),
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          allSelected ? context.l10n.downloadedAlbumAllSelected : context.l10n.downloadedAlbumTapToSelect,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      if (allSelected) {
                        _exitSelectionMode();
                      } else {
                        _selectAll(tracks);
                      }
                    },
                    icon: Icon(allSelected ? Icons.deselect : Icons.select_all, size: 20),
                    label: Text(allSelected ? context.l10n.actionDeselect : context.l10n.actionSelectAll),
                    style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: selectedCount > 0 ? () => _deleteSelected(tracks) : null,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    selectedCount > 0 
                        ? context.l10n.downloadedAlbumDeleteCount(selectedCount)
                        : context.l10n.downloadedAlbumSelectToDelete,
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: selectedCount > 0 ? colorScheme.error : colorScheme.surfaceContainerHighest,
                    foregroundColor: selectedCount > 0 ? colorScheme.onError : colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
