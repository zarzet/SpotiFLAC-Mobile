import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:open_filex/open_filex.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/utils/mime_utils.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/screens/track_metadata_screen.dart';
import 'package:spotiflac_android/screens/downloaded_album_screen.dart';

class _GroupedAlbum {
  final String albumName;
  final String artistName;
  final String? coverUrl;
  final List<DownloadHistoryItem> tracks;
  final DateTime latestDownload;
  final String searchKey;

  _GroupedAlbum({
    required this.albumName,
    required this.artistName,
    this.coverUrl,
    required this.tracks,
    required this.latestDownload,
  }) : searchKey = '${albumName.toLowerCase()}|${artistName.toLowerCase()}';

  String get key => '$albumName|$artistName';
}

class _HistoryStats {
  final Map<String, int> albumCounts;
  final List<_GroupedAlbum> groupedAlbums;
  final int albumCount;
  final int singleTracks;

  const _HistoryStats({
    required this.albumCounts,
    required this.groupedAlbums,
    required this.albumCount,
    required this.singleTracks,
  });
}

Map<String, List<String>> _filterHistoryInIsolate(
  Map<String, Object> payload,
) {
  final entries = (payload['entries'] as List).cast<List>();
  final albumCounts = (payload['albumCounts'] as Map).cast<String, int>();
  final query = (payload['query'] as String?) ?? '';

  final allIds = <String>[];
  final albumIds = <String>[];
  final singleIds = <String>[];

  for (final entry in entries) {
    final id = entry[0] as String;
    final albumKey = entry[1] as String;
    final searchKey = entry[2] as String;

    if (query.isNotEmpty && !searchKey.contains(query)) {
      continue;
    }

    allIds.add(id);
    final count = albumCounts[albumKey] ?? 0;
    if (count > 1) {
      albumIds.add(id);
    } else if (count == 1) {
      singleIds.add(id);
    }
  }

  return {
    'all': allIds,
    'albums': albumIds,
    'singles': singleIds,
  };
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

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  PageController? _filterPageController;
  final List<String> _filterModes = ['all', 'albums', 'singles'];
  bool _isPageControllerInitialized = false;

// Search functionality
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Timer? _searchDebounce;
  List<DownloadHistoryItem>? _historyItemsCache;
  _HistoryStats? _historyStatsCache;
  final Map<String, String> _searchIndexCache = {};
  Map<String, DownloadHistoryItem> _historyItemsById = {};
  List<List<String>> _historyFilterEntries = const [];
  Map<String, List<DownloadHistoryItem>> _filteredHistoryCache = const {};
  List<DownloadHistoryItem>? _filterItemsCache;
  String _filterQueryCache = '';
  bool _filterRefreshScheduled = false;
  bool _isFilteringHistory = false;
  int _filterRequestId = 0;
  static const int _filterIsolateThreshold = 800;



  @override
  void initState() {
    super.initState();
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
    _searchController.dispose();
    _searchFocusNode.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _searchDebounce?.cancel();
    final normalized = value.trim().toLowerCase();
    _searchDebounce = Timer(const Duration(milliseconds: 180), () {
      if (!mounted || _searchQuery == normalized) return;
      setState(() => _searchQuery = normalized);
      _requestFilterRefresh();
    });
  }

  void _clearSearch() {
    _searchDebounce?.cancel();
    if (_searchQuery.isEmpty) return;
    setState(() => _searchQuery = '');
    _requestFilterRefresh();
  }

  void _ensureHistoryCaches(List<DownloadHistoryItem> items) {
    if (identical(items, _historyItemsCache)) return;
    _historyItemsCache = items;
    _historyStatsCache = _buildHistoryStats(items);
    _searchIndexCache
      ..clear()
      ..addEntries(
        items.map((item) => MapEntry(item.id, _buildSearchKey(item))),
      );
    _historyItemsById = {for (final item in items) item.id: item};
    _historyFilterEntries = List<List<String>>.generate(
      items.length,
      (index) {
        final item = items[index];
        final searchKey =
            _searchIndexCache[item.id] ?? _buildSearchKey(item);
final albumKey =
            '${item.albumName.toLowerCase()}|${(item.albumArtist ?? item.artistName).toLowerCase()}';
        return [item.id, albumKey, searchKey];
      },
      growable: false,
    );
    _requestFilterRefresh();
  }

  String _buildSearchKey(DownloadHistoryItem item) {
    return '${item.trackName} ${item.artistName} ${item.albumName}'
        .toLowerCase();
  }

  bool _isFilterCacheValid(List<DownloadHistoryItem> items, String query) {
    return identical(items, _filterItemsCache) && query == _filterQueryCache;
  }

  void _requestFilterRefresh() {
    if (_filterRefreshScheduled) return;
    _filterRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _filterRefreshScheduled = false;
      if (!mounted) return;
      _scheduleHistoryFilterUpdate();
    });
  }

  void _scheduleHistoryFilterUpdate() {
    final items = _historyItemsCache;
    if (items == null) return;
    final query = _searchQuery;
    if (_isFilterCacheValid(items, query)) return;

    final albumCounts =
        _historyStatsCache?.albumCounts ?? const <String, int>{};
    if (items.isEmpty) {
      setState(() {
        _filteredHistoryCache = const {};
        _filterItemsCache = items;
        _filterQueryCache = query;
        _isFilteringHistory = false;
      });
      return;
    }

    if (items.length <= _filterIsolateThreshold) {
      final filteredAll =
          _filterHistoryItems(items, 'all', albumCounts, query);
      final filteredAlbums =
          _filterHistoryItems(items, 'albums', albumCounts, query);
      final filteredSingles =
          _filterHistoryItems(items, 'singles', albumCounts, query);
      setState(() {
        _filteredHistoryCache = {
          'all': filteredAll,
          'albums': filteredAlbums,
          'singles': filteredSingles,
        };
        _filterItemsCache = items;
        _filterQueryCache = query;
        _isFilteringHistory = false;
      });
      return;
    }

    if (!_isFilteringHistory) {
      setState(() => _isFilteringHistory = true);
    }

    final requestId = ++_filterRequestId;
    final payload = <String, Object>{
      'entries': _historyFilterEntries,
      'albumCounts': albumCounts,
      'query': query,
    };

    compute(_filterHistoryInIsolate, payload).then((result) {
      if (!mounted || requestId != _filterRequestId) return;
      final itemsById = _historyItemsById;
      final filtered = <String, List<DownloadHistoryItem>>{};
      for (final entry in result.entries) {
        filtered[entry.key] = entry.value
            .map((id) => itemsById[id])
            .whereType<DownloadHistoryItem>()
            .toList(growable: false);
      }
      setState(() {
        _filteredHistoryCache = filtered;
        _filterItemsCache = items;
        _filterQueryCache = query;
        _isFilteringHistory = false;
      });
    });
  }

  List<DownloadHistoryItem> _resolveHistoryItems({
    required String filterMode,
    required List<DownloadHistoryItem> allHistoryItems,
    required Map<String, int> albumCounts,
  }) {
    final query = _searchQuery;
    if (_isFilterCacheValid(allHistoryItems, query)) {
      final cached = _filteredHistoryCache[filterMode];
      if (cached != null) return cached;
    }
    if (allHistoryItems.isEmpty) return const [];
    if (query.isEmpty && filterMode == 'all') return allHistoryItems;
    if (allHistoryItems.length <= _filterIsolateThreshold) {
      return _filterHistoryItems(
        allHistoryItems,
        filterMode,
        albumCounts,
        query,
      );
    }
    return const [];
  }

  bool _shouldShowFilteringIndicator({
    required List<DownloadHistoryItem> allHistoryItems,
    required String filterMode,
  }) {
    if (allHistoryItems.isEmpty) return false;
    if (_searchQuery.isEmpty && filterMode == 'all') return false;
    if (allHistoryItems.length <= _filterIsolateThreshold) return false;
    return !_isFilterCacheValid(allHistoryItems, _searchQuery) ||
        _isFilteringHistory;
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

  void _precacheCover(String? url) {
    if (url == null || url.isEmpty) return;
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return;
    }
    precacheImage(
      CachedNetworkImageProvider(url, cacheManager: CoverCacheManager.instance),
      context,
    );
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

_precacheCover(historyItem.coverUrl);
    _searchFocusNode.unfocus();
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
    ).then((_) => _searchFocusNode.unfocus());
  }

  void _navigateToHistoryMetadataScreen(DownloadHistoryItem item) {
    _precacheCover(item.coverUrl);
    _searchFocusNode.unfocus();
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
    ).then((_) => _searchFocusNode.unfocus());
  }

List<DownloadHistoryItem> _filterHistoryItems(
    List<DownloadHistoryItem> items,
    String filterMode,
    Map<String, int> albumCounts, [
    String searchQuery = '',
  ]) {
    // First apply search filter
    var filteredItems = items;
    if (searchQuery.isNotEmpty) {
      final query = searchQuery;
      filteredItems = items.where((item) {
        final searchKey =
            _searchIndexCache[item.id] ?? _buildSearchKey(item);
        if (!_searchIndexCache.containsKey(item.id)) {
          _searchIndexCache[item.id] = searchKey;
        }
        return searchKey.contains(query);
      }).toList();
    }

    // Then apply filter mode
    if (filterMode == 'all') return filteredItems;

switch (filterMode) {
      case 'albums':
        return filteredItems.where((item) {
          final key =
              '${item.albumName.toLowerCase()}|${(item.albumArtist ?? item.artistName).toLowerCase()}';
          return (albumCounts[key] ?? 0) > 1;
        }).toList();
      case 'singles':
        return filteredItems.where((item) {
          final key =
              '${item.albumName.toLowerCase()}|${(item.albumArtist ?? item.artistName).toLowerCase()}';
          return (albumCounts[key] ?? 0) == 1;
        }).toList();
      default:
        return filteredItems;
    }
  }

_HistoryStats _buildHistoryStats(List<DownloadHistoryItem> items) {
    final albumCounts = <String, int>{};
    final albumMap = <String, List<DownloadHistoryItem>>{};
    for (final item in items) {
      // Use lowercase key for case-insensitive grouping
      final key = '${item.albumName.toLowerCase()}|${(item.albumArtist ?? item.artistName).toLowerCase()}';
      albumCounts[key] = (albumCounts[key] ?? 0) + 1;
      albumMap.putIfAbsent(key, () => []).add(item);
    }

    int singleTracks = 0;
    for (final item in items) {
      final key = '${item.albumName.toLowerCase()}|${(item.albumArtist ?? item.artistName).toLowerCase()}';
      if ((albumCounts[key] ?? 0) <= 1) {
        singleTracks++;
      }
    }

    final groupedAlbums = <_GroupedAlbum>[];
    albumMap.forEach((_, tracks) {
      if (tracks.length <= 1) return;
      tracks.sort((a, b) {
        final aNum = a.trackNumber ?? 999;
        final bNum = b.trackNumber ?? 999;
        return aNum.compareTo(bNum);
      });

      groupedAlbums.add(_GroupedAlbum(
        albumName: tracks.first.albumName,
        artistName: tracks.first.albumArtist ?? tracks.first.artistName,
        coverUrl: tracks.first.coverUrl,
        tracks: tracks,
        latestDownload: tracks
            .map((t) => t.downloadedAt)
            .reduce((a, b) => a.isAfter(b) ? a : b),
      ));
    });

    groupedAlbums.sort((a, b) => b.latestDownload.compareTo(a.latestDownload));

    int albumCount = 0;
    for (final count in albumCounts.values) {
      if (count > 1) albumCount++;
    }

    return _HistoryStats(
      albumCounts: albumCounts,
      groupedAlbums: groupedAlbums,
      albumCount: albumCount,
      singleTracks: singleTracks,
    );
  }

void _navigateToDownloadedAlbum(_GroupedAlbum album) {
    _searchFocusNode.unfocus();
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
    ).then((_) => _searchFocusNode.unfocus());
  }

  @override
  Widget build(BuildContext context) {
    _initializePageController();

final queueItems = ref.watch(downloadQueueProvider.select((s) => s.items));
    final allHistoryItems = ref.watch(
      downloadHistoryProvider.select((s) => s.items),
    );
    _ensureHistoryCaches(allHistoryItems);
    final historyViewMode = ref.watch(
      settingsProvider.select((s) => s.historyViewMode),
    );
    final historyFilterMode = ref.watch(
      settingsProvider.select((s) => s.historyFilterMode),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    final historyStats =
        _historyStatsCache ?? _buildHistoryStats(allHistoryItems);
    final groupedAlbums = historyStats.groupedAlbums;
    final albumCount = historyStats.albumCount;
    final singleCount = historyStats.singleTracks;

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
          // ScrollConfiguration disables stretch overscroll to fix _StretchController exception
          // This is a known Flutter issue with NestedScrollView + Material 3 stretch indicator
          ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(
              overscroll: false,
            ),
            child: NestedScrollView(
              headerSliverBuilder: (context, innerBoxIsScrolled) => [
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

              // Search bar - always at top
              if (allHistoryItems.isNotEmpty || queueItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                    child: GestureDetector(
                      onTap: () {},
                      child: TextField(
                        controller: _searchController,
                        focusNode: _searchFocusNode,
                        autofocus: false,
                        canRequestFocus: true,
                        decoration: InputDecoration(
                          hintText: context.l10n.historySearchHint,
                          prefixIcon: const Icon(Icons.search),
                          suffixIcon: _searchQuery.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    _searchController.clear();
                                    _clearSearch();
                                    FocusScope.of(context).unfocus();
                                  },
                                )
                              : null,
                          filled: true,
                          fillColor: colorScheme.surfaceContainerHighest,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                              width: 1,
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(
                              color: colorScheme.outlineVariant,
                              width: 1.5,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(28),
                            borderSide: BorderSide(
                              color: colorScheme.primary,
                              width: 2.5,
                            ),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 12,
                          ),
                        ),
                        onChanged: _onSearchChanged,
                        onTapOutside: (_) {
                          FocusScope.of(context).unfocus();
                        },
                      ),
                    ),
                  ),
                ),

              if (queueItems.isNotEmpty)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                    child: Row(
                      children: [
                        Text(
                          'Downloading (${queueItems.length})',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        _buildPauseResumeButton(context, ref, colorScheme),
                      ],
                    ),
                  ),
                ),

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
                  
                  if (page == 0 && overscroll < 0) {
                    final currentOffset = parentController.offset;
                    final targetOffset = (currentOffset + overscroll).clamp(
                      0.0,
                      parentController.position.maxScrollExtent,
                    );
                    parentController.jumpTo(targetOffset);
                    return true;
                  }
                  
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

                if (notification is ScrollEndNotification) {
                  if (page == 0 || page == 2) {
                    final currentPage = parentController.page ?? widget.parentPageIndex.toDouble();
                    final historyPage = widget.parentPageIndex.toDouble();
                    final offset = currentPage - historyPage;
                    
                    if (offset.abs() > 0.01) {
                      if (offset < -0.3) {
                        parentController.animateToPage(
                          widget.parentPageIndex - 1,
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                        );
                      } else if (offset > 0.3) {
                        parentController.animateToPage(
                          widget.nextPageIndex ?? (widget.parentPageIndex + 1),
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOutCubic,
                        );
                      } else {
                        parentController.jumpToPage(widget.parentPageIndex);
                      }
                    }
                  }
                }

                return false;
              },
              child: PageView.builder(
                controller: _filterPageController!,
                physics: const ClampingScrollPhysics(),
                onPageChanged: _onFilterPageChanged,
                itemCount: _filterModes.length,
                itemBuilder: (context, index) {
                  final filterMode = _filterModes[index];
                  return _buildFilterContent(
                    context: context,
                    colorScheme: colorScheme,
                    filterMode: filterMode,
                    allHistoryItems: allHistoryItems,
                    historyViewMode: historyViewMode,
                    queueItems: queueItems,
                    groupedAlbums: groupedAlbums,
                    albumCounts: historyStats.albumCounts,
                  );
                },
              ),
            ),
          ),
          ), // ScrollConfiguration

          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _isSelectionMode ? 0 : -(200 + bottomPadding),
child: _buildSelectionBottomBar(
              context,
              colorScheme,
              _resolveHistoryItems(
                filterMode: historyFilterMode,
                allHistoryItems: allHistoryItems,
                albumCounts: historyStats.albumCounts,
              ),
              bottomPadding,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterContent({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String filterMode,
    required List<DownloadHistoryItem> allHistoryItems,
    required String historyViewMode,
    required List<DownloadItem> queueItems,
    required List<_GroupedAlbum> groupedAlbums,
required Map<String, int> albumCounts,
  }) {
final historyItems = _resolveHistoryItems(
      filterMode: filterMode,
      allHistoryItems: allHistoryItems,
      albumCounts: albumCounts,
    );
    final showFilteringIndicator = _shouldShowFilteringIndicator(
      allHistoryItems: allHistoryItems,
      filterMode: filterMode,
    );

    // Filter grouped albums based on search query
    final searchQuery = _searchQuery;
    final filteredGroupedAlbums = searchQuery.isEmpty
        ? groupedAlbums
        : groupedAlbums
            .where((album) => album.searchKey.contains(searchQuery))
            .toList();

    return CustomScrollView(
      slivers: [
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

if (filteredGroupedAlbums.isNotEmpty &&
            queueItems.isEmpty &&
            filterMode == 'albums')
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                '${filteredGroupedAlbums.length} ${filteredGroupedAlbums.length == 1 ? 'album' : 'albums'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),

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

        if (showFilteringIndicator)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              child: Row(
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Filtering...',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ),

if (filterMode == 'albums' && filteredGroupedAlbums.isNotEmpty)
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
                final album = filteredGroupedAlbums[index];
                return KeyedSubtree(
                  key: ValueKey(album.key),
                  child: _buildAlbumGridItem(context, album, colorScheme),
                );
              }, childCount: filteredGroupedAlbums.length),
            ),
          ),

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
                  }, childCount: historyItems.length                ),
              ),

if (queueItems.isEmpty &&
            historyItems.isEmpty &&
            (filterMode != 'albums' || filteredGroupedAlbums.isEmpty) &&
            !showFilteringIndicator)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(
              context,
              colorScheme,
              filterMode,
            ),
          )
        else
          SliverToBoxAdapter(
            child: SizedBox(height: _isSelectionMode ? 100 : 16),
          ),
      ],
    );
  }

  Widget _buildPauseResumeButton(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    final isPaused = ref.watch(downloadQueueProvider.select((s) => s.isPaused));
    
    return TextButton.icon(
      onPressed: () {
        ref.read(downloadQueueProvider.notifier).togglePause();
      },
      icon: Icon(
        isPaused ? Icons.play_arrow : Icons.pause,
        size: 18,
      ),
      label: Text(
        isPaused ? context.l10n.actionResume : context.l10n.actionPause,
      ),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: isPaused ? colorScheme.primary : colorScheme.onSurfaceVariant,
      ),
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
                          cacheManager: CoverCacheManager.instance,
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
          Text(
            album.albumName,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600            ),
          ),
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
              cacheManager: CoverCacheManager.instance,
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
                              cacheManager: CoverCacheManager.instance,
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
                        cacheManager: CoverCacheManager.instance,
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
