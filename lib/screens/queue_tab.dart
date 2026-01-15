import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/utils/mime_utils.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/screens/track_metadata_screen.dart';
import 'package:spotiflac_android/screens/downloaded_album_screen.dart';

/// Grouped album data for history display
class _GroupedAlbum {
  final String albumName;
  final String artistName;
  final String? coverUrl;
  final List<DownloadHistoryItem> tracks;
  final DateTime latestDownload;

  _GroupedAlbum({
    required this.albumName,
    required this.artistName,
    this.coverUrl,
    required this.tracks,
    required this.latestDownload,
  });

  String get key => '$albumName|$artistName';
}

class QueueTab extends ConsumerStatefulWidget {
  final PageController? parentPageController;
  final int parentPageIndex;
  final int? nextPageIndex;

  const QueueTab({
    super.key,
    this.parentPageController,
    this.parentPageIndex = 1,
    this.nextPageIndex,
  });

  @override
  ConsumerState<QueueTab> createState() => _QueueTabState();
}

class _QueueTabState extends ConsumerState<QueueTab> {
  final Map<String, bool> _fileExistsCache = {};
  final Set<String> _pendingChecks = {};
  static const int _maxCacheSize = 500;

  // Multi-select state
  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  // Filter page controller for swipe between All/Albums/Singles
  PageController? _filterPageController;
  final List<String> _filterModes = ['all', 'albums', 'singles'];
  bool _isPageControllerInitialized = false;



  @override
  void initState() {
    super.initState();
    // Will be initialized in build when we have access to ref
  }

  void _initializePageController() {
    if (_isPageControllerInitialized) return;
    _isPageControllerInitialized = true;
    final currentFilter = ref.read(settingsProvider).historyFilterMode;
    final initialPage = _filterModes.indexOf(currentFilter).clamp(0, 2);
    _filterPageController = PageController(initialPage: initialPage);
  }

  @override
  void dispose() {
    _filterPageController?.dispose();
    super.dispose();
  }

  void _onFilterPageChanged(int index) {
    final filterMode = _filterModes[index];
    ref.read(settingsProvider.notifier).setHistoryFilterMode(filterMode);
  }

  void _animateToFilterPage(int index) {
    _filterPageController?.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
    );
  }

  /// Enter selection mode with initial item
  void _enterSelectionMode(String itemId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isSelectionMode = true;
      _selectedIds.add(itemId);
    });
  }

  /// Exit selection mode
  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds.clear();
    });
  }

  /// Toggle item selection
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

  /// Select all visible items
  void _selectAll(List<DownloadHistoryItem> items) {
    setState(() {
      _selectedIds.addAll(items.map((e) => e.id));
    });
  }

  /// Delete selected items
  Future<void> _deleteSelected() async {
    final count = _selectedIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.dialogDeleteSelectedTitle),
        content: Text(context.l10n.dialogDeleteSelectedMessage(count)),
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
      final items = ref.read(downloadHistoryProvider).items;

      int deletedCount = 0;
      for (final id in _selectedIds) {
        final item = items.where((e) => e.id == id).firstOrNull;
        if (item != null) {
          try {
            final cleanPath = _cleanFilePath(item.filePath);
            final file = File(cleanPath);
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
          SnackBar(
            content: Text(context.l10n.snackbarDeletedTracks(deletedCount)),
          ),
        );
      }
    }
  }

  /// Strip EXISTS: prefix from file path (legacy history items)
  String _cleanFilePath(String? filePath) {
    if (filePath == null) return '';
    if (filePath.startsWith('EXISTS:')) {
      return filePath.substring(7);
    }
    return filePath;
  }

  bool _checkFileExists(String? filePath) {
    if (filePath == null) return false;
    final cleanPath = _cleanFilePath(filePath);
    if (cleanPath.isEmpty) return false;
    if (_fileExistsCache.containsKey(cleanPath)) {
      return _fileExistsCache[cleanPath]!;
    }
    if (_pendingChecks.contains(cleanPath)) {
      return true;
    }
    if (_fileExistsCache.length >= _maxCacheSize) {
      _fileExistsCache.remove(_fileExistsCache.keys.first);
    }
    _pendingChecks.add(cleanPath);
    Future.microtask(() async {
      final exists = await File(cleanPath).exists();
      _pendingChecks.remove(cleanPath);
      if (mounted && _fileExistsCache[cleanPath] != exists) {
        setState(() => _fileExistsCache[cleanPath] = exists);
      }
    });
    return true;
  }

  Future<void> _openFile(String filePath) async {
    final cleanPath = _cleanFilePath(filePath);
    try {
      final mimeType = audioMimeTypeForPath(cleanPath);
      await OpenFilex.open(cleanPath, type: mimeType);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(context.l10n.snackbarCannotOpenFile(e.toString()))));
      }
    }
  }

  void _navigateToMetadataScreen(DownloadItem item) {
    final historyItem = ref
        .read(downloadHistoryProvider)
        .items
        .firstWhere(
          (h) => h.filePath == item.filePath,
          orElse: () => DownloadHistoryItem(
            id: item.id,
            trackName: item.track.name,
            artistName: item.track.artistName,
            albumName: item.track.albumName,
            coverUrl: item.track.coverUrl,
            filePath: item.filePath ?? '',
            downloadedAt: DateTime.now(),
            service: item.service,
          ),
        );

    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) =>
            TrackMetadataScreen(item: historyItem),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  void _navigateToHistoryMetadataScreen(DownloadHistoryItem item) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) =>
            TrackMetadataScreen(item: item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  /// Filter history items based on current filter mode
  /// Album = track yang albumnya punya >1 track di history
  /// Single = track yang albumnya cuma 1 track di history
  List<DownloadHistoryItem> _filterHistoryItems(
    List<DownloadHistoryItem> items,
    String filterMode,
  ) {
    if (filterMode == 'all') return items;

    // Count tracks per album
    final albumCounts = <String, int>{};
    for (final item in items) {
      final key = '${item.albumName}|${item.albumArtist ?? item.artistName}';
      albumCounts[key] = (albumCounts[key] ?? 0) + 1;
    }

    switch (filterMode) {
      case 'albums':
        // Album = more than 1 track from same album in history
        return items.where((item) {
          final key =
              '${item.albumName}|${item.albumArtist ?? item.artistName}';
          return (albumCounts[key] ?? 0) > 1;
        }).toList();
      case 'singles':
        // Single = only 1 track from that album in history
        return items.where((item) {
          final key =
              '${item.albumName}|${item.albumArtist ?? item.artistName}';
          return (albumCounts[key] ?? 0) == 1;
        }).toList();
      default:
        return items;
    }
  }

  /// Count albums vs singles for filter chips
  Map<String, int> _countAlbumsAndSingles(List<DownloadHistoryItem> items) {
    // Count tracks per album
    final albumCounts = <String, int>{};
    for (final item in items) {
      final key = '${item.albumName}|${item.albumArtist ?? item.artistName}';
      albumCounts[key] = (albumCounts[key] ?? 0) + 1;
    }

    int albumTracks = 0;
    int singleTracks = 0;

    for (final item in items) {
      final key = '${item.albumName}|${item.albumArtist ?? item.artistName}';
      if ((albumCounts[key] ?? 0) > 1) {
        albumTracks++;
      } else {
        singleTracks++;
      }
    }

    return {'albums': albumTracks, 'singles': singleTracks};
  }

  /// Group history items by album (for Albums filter view)
  List<_GroupedAlbum> _groupByAlbum(List<DownloadHistoryItem> items) {
    final albumMap = <String, List<DownloadHistoryItem>>{};

    for (final item in items) {
      final key = '${item.albumName}|${item.albumArtist ?? item.artistName}';
      albumMap.putIfAbsent(key, () => []).add(item);
    }

    // Only include albums with more than 1 track
    final groupedAlbums = albumMap.entries.where((e) => e.value.length > 1).map(
      (e) {
        final tracks = e.value;
        // Sort tracks by track number
        tracks.sort((a, b) {
          final aNum = a.trackNumber ?? 999;
          final bNum = b.trackNumber ?? 999;
          return aNum.compareTo(bNum);
        });

        return _GroupedAlbum(
          albumName: tracks.first.albumName,
          artistName: tracks.first.albumArtist ?? tracks.first.artistName,
          coverUrl: tracks.first.coverUrl,
          tracks: tracks,
          latestDownload: tracks
              .map((t) => t.downloadedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b),
        );
      },
    ).toList();

    // Sort by latest download
    groupedAlbums.sort((a, b) => b.latestDownload.compareTo(a.latestDownload));

    return groupedAlbums;
  }

  /// Count unique albums (for filter chip badge)
  int _countUniqueAlbums(List<DownloadHistoryItem> items) {
    final albumKeys = <String>{};
    for (final item in items) {
      final key = '${item.albumName}|${item.albumArtist ?? item.artistName}';
      albumKeys.add(key);
    }

    // Count albums with more than 1 track
    int count = 0;
    for (final key in albumKeys) {
      final trackCount = items
          .where(
            (i) => '${i.albumName}|${i.albumArtist ?? i.artistName}' == key,
          )
          .length;
      if (trackCount > 1) count++;
    }
    return count;
  }

  void _navigateToDownloadedAlbum(_GroupedAlbum album) {
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) =>
            DownloadedAlbumScreen(
              albumName: album.albumName,
              artistName: album.artistName,
              coverUrl: album.coverUrl,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Initialize page controller on first build
    _initializePageController();

    final queueItems = ref.watch(downloadQueueProvider.select((s) => s.items));
    final isProcessing = ref.watch(
      downloadQueueProvider.select((s) => s.isProcessing),
    );
    final isPaused = ref.watch(downloadQueueProvider.select((s) => s.isPaused));
    final queuedCount = ref.watch(
      downloadQueueProvider.select((s) => s.queuedCount),
    );
    final completedCount = ref.watch(
      downloadQueueProvider.select((s) => s.completedCount),
    );
    final allHistoryItems = ref.watch(
      downloadHistoryProvider.select((s) => s.items),
    );
    final historyViewMode = ref.watch(
      settingsProvider.select((s) => s.historyViewMode),
    );
    final historyFilterMode = ref.watch(
      settingsProvider.select((s) => s.historyFilterMode),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    // Group albums for Albums filter view
    final groupedAlbums = _groupByAlbum(allHistoryItems);

    // Count for filter chips
    final counts = _countAlbumsAndSingles(allHistoryItems);
    final albumCount = _countUniqueAlbums(allHistoryItems);
    final singleCount = counts['singles'] ?? 0;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop && _isSelectionMode) {
          _exitSelectionMode();
        }
      },
      child: Stack(
        children: [
          NestedScrollView(
            headerSliverBuilder: (context, innerBoxIsScrolled) => [
              // App Bar - always normal style
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
                    final expandRatio =
                        ((constraints.maxHeight - minHeight) /
                                (maxHeight - minHeight))
                            .clamp(0.0, 1.0);

                    return FlexibleSpaceBar(
                      expandedTitleScale: 1.0,
                      titlePadding: const EdgeInsets.only(left: 24, bottom: 16),
                      title: Text(
                        context.l10n.historyTitle,
                        style: TextStyle(
                          fontSize: 20 + (14 * expandRatio),
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onSurface,
                        ),
                      ),
                    );
                  },
                ),
              ),

              // Pause/Resume controls
              if ((isProcessing || queuedCount > 0) &&
                  (queueItems.length > 1 || isPaused))
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isPaused
                                    ? colorScheme.errorContainer
                                    : colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                isPaused ? Icons.pause : Icons.downloading,
                                color: isPaused
                                    ? colorScheme.onErrorContainer
                                    : colorScheme.onPrimaryContainer,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                isPaused
                                    ? 'Paused'
                                    : '$completedCount/${queueItems.length}',
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ),
                            FilledButton.tonal(
                              onPressed: () => ref
                                  .read(downloadQueueProvider.notifier)
                                  .togglePause(),
                              child: Text(isPaused ? 'Resume' : 'Pause'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

              // Queue header
              if (queueItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'Downloading (${queueItems.length})',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),

              // Queue list
              if (queueItems.isNotEmpty)
                SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = queueItems[index];
                    return KeyedSubtree(
                      key: ValueKey(item.id),
                      child: _buildQueueItem(context, item, colorScheme),
                    );
                  }, childCount: queueItems.length),
                ),

              // Filter chips (only show when history has items)
              if (allHistoryItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          _FilterChip(
                            label: context.l10n.historyFilterAll,
                            count: allHistoryItems.length,
                            isSelected: historyFilterMode == 'all',
                            onTap: () {
                              _animateToFilterPage(0);
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: context.l10n.historyFilterAlbums,
                            count: albumCount,
                            isSelected: historyFilterMode == 'albums',
                            onTap: () {
                              _animateToFilterPage(1);
                            },
                          ),
                          const SizedBox(width: 8),
                          _FilterChip(
                            label: context.l10n.historyFilterSingles,
                            count: singleCount,
                            isSelected: historyFilterMode == 'singles',
                            onTap: () {
                              _animateToFilterPage(2);
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
            body: NotificationListener<ScrollNotification>(
              onNotification: (notification) {
                final parentController = widget.parentPageController;
                if (parentController == null || !parentController.hasClients) {
                  return false;
                }

                final page = _filterPageController!.page?.round() ?? 0;

                if (notification is OverscrollNotification) {
                  final overscroll = notification.overscroll;
                  
                  // At first page and overscrolling to the left -> push parent toward Home
                  if (page == 0 && overscroll < 0) {
                    final currentOffset = parentController.offset;
                    final targetOffset = (currentOffset + overscroll).clamp(
                      0.0,
                      parentController.position.maxScrollExtent,
                    );
                    parentController.jumpTo(targetOffset);
                    return true;
                  }
                  
                  // At last page and overscrolling to the right -> push parent toward next tab
                  if (page == 2 && overscroll > 0) {
                    final currentOffset = parentController.offset;
                    final targetOffset = (currentOffset + overscroll).clamp(
                      0.0,
                      parentController.position.maxScrollExtent,
                    );
                    parentController.jumpTo(targetOffset);
                    return true;
                  }
                }

                // Snap parent to nearest page when scroll ends
                if (notification is ScrollEndNotification) {
                  if (page == 0 || page == 2) {
                    final currentPage = parentController.page ?? widget.parentPageIndex.toDouble();
                    final historyPage = widget.parentPageIndex.toDouble();
                    final offset = currentPage - historyPage;
                    
                    // Only snap if we've moved the parent
                    if (offset.abs() > 0.01) {
                      // Use 0.3 threshold (30%)
                      if (offset < -0.3) {
                        // Swiped enough toward Home - animate to Home
                        parentController.animateToPage(
                          widget.parentPageIndex - 1,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                        );
                      } else if (offset > 0.3) {
                        // Swiped enough toward next tab - animate to next
                        parentController.animateToPage(
                          widget.nextPageIndex ?? (widget.parentPageIndex + 1),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        // Not enough - instant jump back (no animation)
                        parentController.jumpToPage(widget.parentPageIndex);
                      }
                    }
                  }
                }

                return false;
              },
              child: PageView(
                controller: _filterPageController!,
                physics: const ClampingScrollPhysics(),
                onPageChanged: _onFilterPageChanged,
                children: [
                  // All tab
                  _buildFilterContent(
                    context: context,
                    colorScheme: colorScheme,
                    filterMode: 'all',
                    allHistoryItems: allHistoryItems,
                    historyViewMode: historyViewMode,
                    queueItems: queueItems,
                    groupedAlbums: groupedAlbums,
                  ),
                  // Albums tab
                  _buildFilterContent(
                    context: context,
                    colorScheme: colorScheme,
                    filterMode: 'albums',
                    allHistoryItems: allHistoryItems,
                    historyViewMode: historyViewMode,
                    queueItems: queueItems,
                    groupedAlbums: groupedAlbums,
                  ),
                  // Singles tab
                  _buildFilterContent(
                    context: context,
                    colorScheme: colorScheme,
                    filterMode: 'singles',
                    allHistoryItems: allHistoryItems,
                    historyViewMode: historyViewMode,
                    queueItems: queueItems,
                    groupedAlbums: groupedAlbums,
                  ),
                ],
              ),
            ),
          ),

          // Bottom Selection Action Bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _isSelectionMode ? 0 : -(200 + bottomPadding),
            child: _buildSelectionBottomBar(
              context,
              colorScheme,
              _filterHistoryItems(allHistoryItems, historyFilterMode),
              bottomPadding,
            ),
          ),
        ],
      ),
    );
  }

  /// Build content for each filter tab
  Widget _buildFilterContent({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String filterMode,
    required List<DownloadHistoryItem> allHistoryItems,
    required String historyViewMode,
    required List<DownloadItem> queueItems,
    required List<_GroupedAlbum> groupedAlbums,
  }) {
    final historyItems = _filterHistoryItems(allHistoryItems, filterMode);

    return CustomScrollView(
      slivers: [
        // History section header
        if (historyItems.isNotEmpty &&
            queueItems.isEmpty &&
            filterMode != 'albums')
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    '${historyItems.length} ${historyItems.length == 1 ? 'track' : 'tracks'}',
                    style: Theme.of(context).textTheme.bodyMedium
                        ?.copyWith(color: colorScheme.onSurfaceVariant),
                  ),
                  const Spacer(),
                  if (!_isSelectionMode)
                    TextButton.icon(
                      onPressed: historyItems.isNotEmpty
                          ? () => _enterSelectionMode(historyItems.first.id)
                          : null,
                      icon: const Icon(Icons.checklist, size: 18),
                      label: Text(context.l10n.actionSelect),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Albums section header (when Albums filter is selected)
        if (groupedAlbums.isNotEmpty &&
            queueItems.isEmpty &&
            filterMode == 'albums')
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                '${groupedAlbums.length} ${groupedAlbums.length == 1 ? 'album' : 'albums'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

        // History section header when queue has items
        if (historyItems.isNotEmpty && queueItems.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                'Downloaded',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),

        // Albums Grid (when Albums filter is selected)
        if (filterMode == 'albums' && groupedAlbums.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    mainAxisSpacing: 12,
                    crossAxisSpacing: 12,
                    childAspectRatio: 0.75,
                  ),
              delegate: SliverChildBuilderDelegate((context, index) {
                final album = groupedAlbums[index];
                return KeyedSubtree(
                  key: ValueKey(album.key),
                  child: _buildAlbumGridItem(context, album, colorScheme),
                );
              }, childCount: groupedAlbums.length),
            ),
          ),

        // History - Grid or List (for All and Singles filter)
        if (historyItems.isNotEmpty && filterMode != 'albums')
          historyViewMode == 'grid'
              ? SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverGrid(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 0.75,
                        ),
                    delegate: SliverChildBuilderDelegate((
                      context,
                      index,
                    ) {
                      final item = historyItems[index];
                      return KeyedSubtree(
                        key: ValueKey(item.id),
                        child: _buildHistoryGridItem(
                          context,
                          item,
                          colorScheme,
                        ),
                      );
                    }, childCount: historyItems.length),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = historyItems[index];
                    return KeyedSubtree(
                      key: ValueKey(item.id),
                      child: _buildHistoryItem(
                        context,
                        item,
                        colorScheme,
                      ),
                    );
                  }, childCount: historyItems.length),
                ),

        // Empty state
        if (queueItems.isEmpty &&
            historyItems.isEmpty &&
            (filterMode != 'albums' || groupedAlbums.isEmpty))
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(
              context,
              colorScheme,
              filterMode,
            ),
          )
        else
          // Add bottom padding when selection mode is active to avoid overlap with bottom bar
          SliverToBoxAdapter(
            child: SizedBox(height: _isSelectionMode ? 100 : 16),
          ),
      ],
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    ColorScheme colorScheme,
    String filterMode,
  ) {
    String message;
    String subtitle;
    IconData icon;

    switch (filterMode) {
      case 'albums':
        message = 'No album downloads';
        subtitle = 'Download multiple tracks from an album to see them here';
        icon = Icons.album;
        break;
      case 'singles':
        message = 'No single downloads';
        subtitle = 'Single track downloads will appear here';
        icon = Icons.music_note;
        break;
      default:
        message = 'No download history';
        subtitle = 'Downloaded tracks will appear here';
        icon = Icons.history;
    }

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: colorScheme.onSurfaceVariant),
          const SizedBox(height: 16),
          Text(
            message,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  /// Build album grid item for grouped albums view
  Widget _buildAlbumGridItem(
    BuildContext context,
    _GroupedAlbum album,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => _navigateToDownloadedAlbum(album),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Album cover with track count badge
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: album.coverUrl != null
                      ? CachedNetworkImage(
                          imageUrl: album.coverUrl!,
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          memCacheWidth: 300,
                          memCacheHeight: 300,
                        )
                      : Container(
                          color: colorScheme.surfaceContainerHighest,
                          child: Center(
                            child: Icon(
                              Icons.album,
                              color: colorScheme.onSurfaceVariant,
                              size: 48,
                            ),
                          ),
                        ),
                ),
                // Track count badge
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.music_note,
                          size: 12,
                          color: colorScheme.onPrimaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${album.tracks.length}',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Album name
          Text(
            album.albumName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          // Artist name
          Text(
            album.artistName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Bottom action bar for selection mode (Material Design 3 style)
  Widget _buildSelectionBottomBar(
    BuildContext context,
    ColorScheme colorScheme,
    List<DownloadHistoryItem> historyItems,
    double bottomPadding,
  ) {
    final selectedCount = _selectedIds.length;
    final allSelected =
        selectedCount == historyItems.length && historyItems.isNotEmpty;

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
              // Handle bar
              Container(
                width: 32,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: colorScheme.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Selection info row
              Row(
                children: [
                  // Close button
                  IconButton.filledTonal(
                    onPressed: _exitSelectionMode,
                    icon: const Icon(Icons.close),
                    style: IconButton.styleFrom(
                      backgroundColor: colorScheme.surfaceContainerHighest,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Selection count
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '$selectedCount selected',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          allSelected
                              ? 'All tracks selected'
                              : 'Tap tracks to select',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  // Select all toggle
                  TextButton.icon(
                    onPressed: () {
                      if (allSelected) {
                        _exitSelectionMode();
                      } else {
                        _selectAll(historyItems);
                      }
                    },
                    icon: Icon(
                      allSelected ? Icons.deselect : Icons.select_all,
                      size: 20,
                    ),
                    label: Text(allSelected ? 'Deselect' : 'Select All'),
                    style: TextButton.styleFrom(
                      foregroundColor: colorScheme.primary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Delete button
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: selectedCount > 0 ? _deleteSelected : null,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    selectedCount > 0
                        ? 'Delete $selectedCount ${selectedCount == 1 ? 'track' : 'tracks'}'
                        : 'Select tracks to delete',
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: selectedCount > 0
                        ? colorScheme.error
                        : colorScheme.surfaceContainerHighest,
                    foregroundColor: selectedCount > 0
                        ? colorScheme.onError
                        : colorScheme.onSurfaceVariant,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQueueItem(
    BuildContext context,
    DownloadItem item,
    ColorScheme colorScheme,
  ) {
    final isCompleted = item.status == DownloadStatus.completed;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: isCompleted ? () => _navigateToMetadataScreen(item) : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              isCompleted
                  ? Hero(
                      tag: 'cover_${item.id}',
                      child: _buildCoverArt(item, colorScheme),
                    )
                  : _buildCoverArt(item, colorScheme),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.track.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.track.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (item.status == DownloadStatus.downloading) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: item.progress > 0 ? item.progress : null,
                                backgroundColor:
                                    colorScheme.surfaceContainerHighest,
                                color: colorScheme.primary,
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            item.speedMBps > 0
                                ? '${(item.progress * 100).toStringAsFixed(0)}% • ${item.speedMBps.toStringAsFixed(1)} MB/s'
                                : '${(item.progress * 100).toStringAsFixed(0)}%',
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                          ),
                        ],
                      ),
                    ],
                    if (item.status == DownloadStatus.failed) ...[
                      const SizedBox(height: 4),
                      Text(
                        item.errorMessage,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _buildActionButtons(context, item, colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCoverArt(DownloadItem item, ColorScheme colorScheme) {
    return item.track.coverUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.track.coverUrl!,
              width: 56,
              height: 56,
              fit: BoxFit.cover,
              memCacheWidth: 112,
              memCacheHeight: 112,
            ),
          )
        : Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
          );
  }

  Widget _buildActionButtons(
    BuildContext context,
    DownloadItem item,
    ColorScheme colorScheme,
  ) {
    switch (item.status) {
      case DownloadStatus.queued:
        return IconButton(
          onPressed: () =>
              ref.read(downloadQueueProvider.notifier).cancelItem(item.id),
          icon: Icon(Icons.close, color: colorScheme.error),
          tooltip: 'Cancel',
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
          ),
        );
      case DownloadStatus.downloading:
        return IconButton(
          onPressed: () =>
              ref.read(downloadQueueProvider.notifier).cancelItem(item.id),
          icon: Icon(Icons.stop, color: colorScheme.error),
          tooltip: 'Stop',
          style: IconButton.styleFrom(
            backgroundColor: colorScheme.errorContainer.withValues(alpha: 0.3),
          ),
        );
      case DownloadStatus.finalizing:
        return SizedBox(
          width: 40,
          height: 40,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                strokeWidth: 3,
                color: colorScheme.tertiary,
              ),
              Icon(Icons.edit_note, color: colorScheme.tertiary, size: 16),
            ],
          ),
        );
      case DownloadStatus.completed:
        final fileExists = _checkFileExists(item.filePath);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (fileExists)
              IconButton(
                onPressed: () => _openFile(item.filePath!),
                icon: Icon(Icons.play_arrow, color: colorScheme.primary),
                tooltip: 'Play',
                style: IconButton.styleFrom(
                  backgroundColor: colorScheme.primaryContainer.withValues(
                    alpha: 0.3,
                  ),
                ),
              )
            else
              Icon(Icons.error_outline, color: colorScheme.error, size: 20),
            const SizedBox(width: 4),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: colorScheme.primaryContainer,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check,
                color: colorScheme.onPrimaryContainer,
                size: 20,
              ),
            ),
          ],
        );
      case DownloadStatus.failed:
      case DownloadStatus.skipped:
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () =>
                  ref.read(downloadQueueProvider.notifier).retryItem(item.id),
              icon: Icon(Icons.refresh, color: colorScheme.primary),
              tooltip: 'Retry',
              style: IconButton.styleFrom(
                backgroundColor: colorScheme.primaryContainer.withValues(
                  alpha: 0.3,
                ),
              ),
            ),
            const SizedBox(width: 4),
            IconButton(
              onPressed: () =>
                  ref.read(downloadQueueProvider.notifier).removeItem(item.id),
              icon: Icon(
                Icons.close,
                color: item.status == DownloadStatus.failed
                    ? colorScheme.error
                    : colorScheme.onSurfaceVariant,
              ),
              tooltip: 'Remove',
              style: item.status == DownloadStatus.failed
                  ? IconButton.styleFrom(
                      backgroundColor: colorScheme.errorContainer.withValues(
                        alpha: 0.3,
                      ),
                    )
                  : null,
            ),
          ],
        );
    }
  }

  Widget _buildHistoryGridItem(
    BuildContext context,
    DownloadHistoryItem item,
    ColorScheme colorScheme,
  ) {
    final fileExists = _checkFileExists(item.filePath);
    final isSelected = _selectedIds.contains(item.id);

    return GestureDetector(
      onTap: _isSelectionMode
          ? () => _toggleSelection(item.id)
          : () => _navigateToHistoryMetadataScreen(item),
      onLongPress: _isSelectionMode ? null : () => _enterSelectionMode(item.id),
      child: Stack(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  AspectRatio(
                    aspectRatio: 1,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: item.coverUrl != null
                          ? CachedNetworkImage(
                              imageUrl: item.coverUrl!,
                              fit: BoxFit.cover,
                              memCacheWidth: 200,
                              memCacheHeight: 200,
                            )
                          : Container(
                              color: colorScheme.surfaceContainerHighest,
                              child: Icon(
                                Icons.music_note,
                                color: colorScheme.onSurfaceVariant,
                                size: 32,
                              ),
                            ),
                    ),
                  ),
                  // Quality badge
                  if (item.quality != null && item.quality!.contains('bit'))
                    Positioned(
                      left: 4,
                      top: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: item.quality!.startsWith('24')
                              ? colorScheme.tertiary
                              : colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          item.quality!.split('/').first,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: item.quality!.startsWith('24')
                                    ? colorScheme.onTertiary
                                    : colorScheme.onSurfaceVariant,
                                fontSize: 9,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                      ),
                    ),
                  // Play button
                  if (fileExists && !_isSelectionMode)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: GestureDetector(
                        onTap: () => _openFile(item.filePath),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: colorScheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: colorScheme.onPrimary,
                            size: 16,
                          ),
                        ),
                      ),
                    ),
                  // Error indicator
                  if (!fileExists && !_isSelectionMode)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: colorScheme.errorContainer,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.error_outline,
                          color: colorScheme.error,
                          size: 14,
                        ),
                      ),
                    ),
                  // Selection overlay
                  if (_isSelectionMode)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                item.trackName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
              ),
              Text(
                item.artistName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          // Selection checkbox
          if (_isSelectionMode)
            Positioned(
              right: 4,
              top: 4,
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? colorScheme.primary : colorScheme.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: isSelected
                        ? colorScheme.primary
                        : colorScheme.outline,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? Icon(Icons.check, color: colorScheme.onPrimary, size: 16)
                    : const SizedBox(width: 16, height: 16),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildHistoryItem(
    BuildContext context,
    DownloadHistoryItem item,
    ColorScheme colorScheme,
  ) {
    final fileExists = _checkFileExists(item.filePath);
    final isSelected = _selectedIds.contains(item.id);
    final date = item.downloadedAt;
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    final dateStr =
        '${months[date.month - 1]} ${date.day}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: _isSelectionMode
            ? () => _toggleSelection(item.id)
            : () => _navigateToHistoryMetadataScreen(item),
        onLongPress: _isSelectionMode
            ? null
            : () => _enterSelectionMode(item.id),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Selection checkbox
              if (_isSelectionMode) ...[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? colorScheme.primary
                        : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.outline,
                      width: 2,
                    ),
                  ),
                  child: isSelected
                      ? Icon(
                          Icons.check,
                          color: colorScheme.onPrimary,
                          size: 16,
                        )
                      : null,
                ),
                const SizedBox(width: 12),
              ],
              // Cover art
              item.coverUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: CachedNetworkImage(
                        imageUrl: item.coverUrl!,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                        memCacheWidth: 112,
                        memCacheHeight: 112,
                      ),
                    )
                  : Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.music_note,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
              const SizedBox(width: 12),

              // Track info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.trackName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.artistName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        Text(
                          dateStr,
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: colorScheme.onSurfaceVariant.withValues(
                                  alpha: 0.7,
                                ),
                              ),
                        ),
                        if (item.quality != null &&
                            item.quality!.contains('bit')) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: item.quality!.startsWith('24')
                                  ? colorScheme.tertiaryContainer
                                  : colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              item.quality!,
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: item.quality!.startsWith('24')
                                        ? colorScheme.onTertiaryContainer
                                        : colorScheme.onSurfaceVariant,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                  ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Action buttons (hide in selection mode)
              if (!_isSelectionMode)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (fileExists)
                      IconButton(
                        onPressed: () => _openFile(item.filePath),
                        icon: Icon(
                          Icons.play_arrow,
                          color: colorScheme.primary,
                        ),
                        tooltip: 'Play',
                        style: IconButton.styleFrom(
                          backgroundColor: colorScheme.primaryContainer
                              .withValues(alpha: 0.3),
                        ),
                      )
                    else
                      Icon(
                        Icons.error_outline,
                        color: colorScheme.error,
                        size: 20,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Filter chip widget for history filtering
class _FilterChip extends StatelessWidget {
  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Material(
      color: isSelected
          ? colorScheme.primaryContainer
          : colorScheme.surfaceContainerHighest,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: isSelected
                      ? colorScheme.onPrimaryContainer
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: isSelected
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : colorScheme.outline.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  count.toString(),
                  style: TextStyle(
                    fontSize: 11,
                    color: isSelected
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w500,
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
