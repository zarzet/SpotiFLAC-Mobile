import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/utils/file_access.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/local_library_provider.dart';
import 'package:spotiflac_android/services/library_database.dart';
import 'package:spotiflac_android/screens/track_metadata_screen.dart';
import 'package:spotiflac_android/screens/downloaded_album_screen.dart';
import 'package:spotiflac_android/screens/local_album_screen.dart';

/// Represents the source of a library item
enum LibraryItemSource { downloaded, local }

/// Unified library item that can come from download history or local library
class UnifiedLibraryItem {
  final String id;
  final String trackName;
  final String artistName;
  final String albumName;
  final String? coverUrl;
  final String? localCoverPath;
  final String filePath;
  final String? quality;
  final DateTime addedAt;
  final LibraryItemSource source;

  final DownloadHistoryItem? historyItem;
  final LocalLibraryItem? localItem;

  UnifiedLibraryItem({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    this.coverUrl,
    this.localCoverPath,
    required this.filePath,
    this.quality,
    required this.addedAt,
    required this.source,
    this.historyItem,
    this.localItem,
  });

  factory UnifiedLibraryItem.fromDownloadHistory(DownloadHistoryItem item) {
    return UnifiedLibraryItem(
      id: 'dl_${item.id}',
      trackName: item.trackName,
      artistName: item.artistName,
      albumName: item.albumName,
      coverUrl: item.coverUrl,
      filePath: item.filePath,
      quality: item.quality,
      addedAt: item.downloadedAt,
      source: LibraryItemSource.downloaded,
      historyItem: item,
    );
  }

  factory UnifiedLibraryItem.fromLocalLibrary(LocalLibraryItem item) {
    String? quality;
    if (item.bitDepth != null && item.sampleRate != null) {
      quality =
          '${item.bitDepth}bit/${(item.sampleRate! / 1000).toStringAsFixed(1)}kHz';
    }
    return UnifiedLibraryItem(
      id: 'local_${item.id}',
      trackName: item.trackName,
      artistName: item.artistName,
      albumName: item.albumName,
      coverUrl: null, // Local library doesn't have cover URLs
      localCoverPath: item.coverPath, // Use extracted cover path
      filePath: item.filePath,
      quality: quality,
      addedAt: item.scannedAt,
      source: LibraryItemSource.local,
      localItem: item,
    );
  }

  /// Returns true if this item has a cover (either URL or local path)
  bool get hasCover =>
      coverUrl != null ||
      (localCoverPath != null && localCoverPath!.isNotEmpty);

  String get searchKey =>
      '${trackName.toLowerCase()}|${artistName.toLowerCase()}|${albumName.toLowerCase()}';
  String get albumKey =>
      '${albumName.toLowerCase()}|${artistName.toLowerCase()}';
}

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

/// Grouped album from local library
class _GroupedLocalAlbum {
  final String albumName;
  final String artistName;
  final String? coverPath; // Local cover file path
  final List<LocalLibraryItem> tracks;
  final DateTime latestScanned;
  final String searchKey;

  _GroupedLocalAlbum({
    required this.albumName,
    required this.artistName,
    this.coverPath,
    required this.tracks,
    required this.latestScanned,
  }) : searchKey = '${albumName.toLowerCase()}|${artistName.toLowerCase()}';

  String get key => '$albumName|$artistName';
}

class _HistoryStats {
  final Map<String, int> albumCounts;
  final Map<String, int> localAlbumCounts; // For identifying local singles
  final List<_GroupedAlbum> groupedAlbums;
  final List<_GroupedLocalAlbum> groupedLocalAlbums; // Local library albums
  final int albumCount;
  final int singleTracks;
  // Local library stats
  final int localAlbumCount;
  final int localSingleTracks;

  const _HistoryStats({
    required this.albumCounts,
    this.localAlbumCounts = const {},
    required this.groupedAlbums,
    this.groupedLocalAlbums = const [],
    required this.albumCount,
    required this.singleTracks,
    this.localAlbumCount = 0,
    this.localSingleTracks = 0,
  });

  /// Total album count including local library
  int get totalAlbumCount => albumCount + localAlbumCount;

  /// Total singles count including local library
  int get totalSingleTracks => singleTracks + localSingleTracks;
}

class _UnifiedCacheEntry {
  final List<DownloadHistoryItem> historyItems;
  final List<LocalLibraryItem> localItems;
  final Map<String, int> localAlbumCounts;
  final String query;
  final List<UnifiedLibraryItem> items;

  const _UnifiedCacheEntry({
    required this.historyItems,
    required this.localItems,
    required this.localAlbumCounts,
    required this.query,
    required this.items,
  });
}

Map<String, List<String>> _filterHistoryInIsolate(Map<String, Object> payload) {
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

  return {'all': allIds, 'albums': albumIds, 'singles': singleIds};
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
  bool _fileExistsUpdateScheduled = false;

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  PageController? _filterPageController;
  final List<String> _filterModes = ['all', 'albums', 'singles'];
  bool _isPageControllerInitialized = false;
  static const List<String> _months = [
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

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();
  String _searchQuery = '';
  Timer? _searchDebounce;
  List<DownloadHistoryItem>? _historyItemsCache;
  List<LocalLibraryItem>? _localLibraryItemsCache;
  _HistoryStats? _historyStatsCache;
  final Map<String, String> _searchIndexCache = {};
  final Map<String, String> _localSearchIndexCache = {};
  Map<String, DownloadHistoryItem> _historyItemsById = {};
  List<List<String>> _historyFilterEntries = const [];
  Map<String, List<DownloadHistoryItem>> _filteredHistoryCache = const {};
  List<DownloadHistoryItem>? _filterItemsCache;
  String _filterQueryCache = '';
  bool _filterRefreshScheduled = false;
  bool _isFilteringHistory = false;
  int _filterRequestId = 0;
  static const int _filterIsolateThreshold = 800;
  List<LocalLibraryItem>? _localFilterItemsCache;
  String _localFilterQueryCache = '';
  List<LocalLibraryItem> _filteredLocalItemsCache = const [];
  final Map<String, _UnifiedCacheEntry> _unifiedItemsCache = {};
  // Advanced filters
  String? _filterSource; // null = all, 'downloaded', 'local'
  String? _filterQuality; // null = all, 'hires', 'cd', 'lossy'
  String? _filterFormat; // null = all, 'flac', 'mp3', 'm4a', 'opus', 'ogg'
  String? _filterDateRange; // null = all, 'today', 'week', 'month', 'year'

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

  void _ensureHistoryCaches(
    List<DownloadHistoryItem> items,
    List<LocalLibraryItem> localItems,
  ) {
    final historyChanged = !identical(items, _historyItemsCache);
    final localChanged = !identical(localItems, _localLibraryItemsCache);

    if (!historyChanged && !localChanged) return;

    _historyItemsCache = items;
    _localLibraryItemsCache = localItems;
    _historyStatsCache = _buildHistoryStats(items, localItems);
    _searchIndexCache
      ..clear()
      ..addEntries(
        items.map((item) => MapEntry(item.id, _buildSearchKey(item))),
      );
    if (localChanged) {
      _localSearchIndexCache
        ..clear()
        ..addEntries(
          localItems.map(
            (item) => MapEntry(item.id, _buildLocalSearchKey(item)),
          ),
        );
      _localFilterItemsCache = null;
      _localFilterQueryCache = '';
      _filteredLocalItemsCache = const [];
    }
    _unifiedItemsCache.clear();
    _historyItemsById = {for (final item in items) item.id: item};
    _historyFilterEntries = List<List<String>>.generate(items.length, (index) {
      final item = items[index];
      final searchKey = _searchIndexCache[item.id] ?? _buildSearchKey(item);
      final albumKey =
          '${item.albumName.toLowerCase()}|${(item.albumArtist ?? item.artistName).toLowerCase()}';
      return [item.id, albumKey, searchKey];
    }, growable: false);
    _requestFilterRefresh();
  }

  String _buildSearchKey(DownloadHistoryItem item) {
    return '${item.trackName} ${item.artistName} ${item.albumName}'
        .toLowerCase();
  }

  String _buildLocalSearchKey(LocalLibraryItem item) {
    return '${item.trackName} ${item.artistName} ${item.albumName}'
        .toLowerCase();
  }

  List<LocalLibraryItem> _filterLocalItems(
    List<LocalLibraryItem> items,
    String query,
  ) {
    if (query.isEmpty) return items;
    if (identical(items, _localFilterItemsCache) &&
        query == _localFilterQueryCache) {
      return _filteredLocalItemsCache;
    }

    final filtered = items
        .where((item) {
          final searchKey =
              _localSearchIndexCache[item.id] ?? _buildLocalSearchKey(item);
          if (!_localSearchIndexCache.containsKey(item.id)) {
            _localSearchIndexCache[item.id] = searchKey;
          }
          return searchKey.contains(query);
        })
        .toList(growable: false);

    _localFilterItemsCache = items;
    _localFilterQueryCache = query;
    _filteredLocalItemsCache = filtered;
    return filtered;
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
      final filteredAll = _applyHistorySearchFilter(items, query);
      final filteredAlbums = _filterHistoryByAlbumCount(
        filteredAll,
        albumCounts,
        2,
      );
      final filteredSingles = _filterHistoryByAlbumCount(
        filteredAll,
        albumCounts,
        1,
      );
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

  List<DownloadHistoryItem> _applyHistorySearchFilter(
    List<DownloadHistoryItem> items,
    String searchQuery,
  ) {
    if (searchQuery.isEmpty) return items;
    final query = searchQuery;
    return items
        .where((item) {
          final searchKey = _searchIndexCache[item.id] ?? _buildSearchKey(item);
          if (!_searchIndexCache.containsKey(item.id)) {
            _searchIndexCache[item.id] = searchKey;
          }
          return searchKey.contains(query);
        })
        .toList(growable: false);
  }

  List<DownloadHistoryItem> _filterHistoryByAlbumCount(
    List<DownloadHistoryItem> items,
    Map<String, int> albumCounts,
    int targetCount,
  ) {
    return items
        .where((item) {
          final key =
              '${item.albumName.toLowerCase()}|${(item.albumArtist ?? item.artistName).toLowerCase()}';
          final count = albumCounts[key] ?? 0;
          return targetCount == 1 ? count == 1 : count >= targetCount;
        })
        .toList(growable: false);
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

  void _selectAll(List<UnifiedLibraryItem> items) {
    setState(() {
      _selectedIds.addAll(items.map((e) => e.id));
    });
  }

  String _getQualityBadgeText(String quality) {
    if (quality.contains('bit')) {
      return quality.split('/').first;
    }
    final bitrateMatch = RegExp(r'(\d+)kbps').firstMatch(quality);
    if (bitrateMatch != null) {
      return '${bitrateMatch.group(1)}k';
    }
    return quality.split(' ').first;
  }

  Future<void> _deleteSelected(List<UnifiedLibraryItem> allItems) async {
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
      final localLibraryDb = LibraryDatabase.instance;

      int deletedCount = 0;
      for (final id in _selectedIds) {
        final item = allItems.where((e) => e.id == id).firstOrNull;
        if (item != null) {
          try {
            final cleanPath = _cleanFilePath(item.filePath);
            await deleteFile(cleanPath);
          } catch (_) {}

          // Remove from appropriate database
          if (item.source == LibraryItemSource.downloaded) {
            historyNotifier.removeFromHistory(item.historyItem!.id);
          } else {
            // Remove from local library database
            await localLibraryDb.deleteByPath(item.filePath);
          }
          deletedCount++;
        }
      }

      // Reload local library if we deleted any local items
      if (allItems.any(
        (i) =>
            _selectedIds.contains(i.id) && i.source == LibraryItemSource.local,
      )) {
        ref.read(localLibraryProvider.notifier).reloadFromStorage();
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
      final exists = await fileExists(cleanPath);
      _pendingChecks.remove(cleanPath);
      final previous = _fileExistsCache[cleanPath];
      _fileExistsCache[cleanPath] = exists;
      if (mounted && previous != exists) {
        _scheduleFileExistsUpdate();
      }
    });
    return true;
  }

  void _scheduleFileExistsUpdate() {
    if (_fileExistsUpdateScheduled) return;
    _fileExistsUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        _fileExistsUpdateScheduled = false;
        return;
      }
      _fileExistsUpdateScheduled = false;
      setState(() {});
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_filterSource != null) count++;
    if (_filterQuality != null) count++;
    if (_filterFormat != null) count++;
    if (_filterDateRange != null) count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _filterSource = null;
      _filterQuality = null;
      _filterFormat = null;
      _filterDateRange = null;
      _unifiedItemsCache.clear();
    });
  }

  List<UnifiedLibraryItem> _applyAdvancedFilters(
    List<UnifiedLibraryItem> items,
  ) {
    if (_activeFilterCount == 0) return items;

    return items
        .where((item) {
          if (_filterSource != null) {
            if (_filterSource == 'downloaded' &&
                item.source != LibraryItemSource.downloaded) {
              return false;
            }
            if (_filterSource == 'local' &&
                item.source != LibraryItemSource.local) {
              return false;
            }
          }

          if (_filterQuality != null && item.quality != null) {
            final quality = item.quality!.toLowerCase();
            switch (_filterQuality) {
              case 'hires':
                if (!quality.startsWith('24')) return false;
              case 'cd':
                if (!quality.startsWith('16')) return false;
              case 'lossy':
                if (quality.startsWith('24') || quality.startsWith('16')) {
                  return false;
                }
            }
          } else if (_filterQuality != null && item.quality == null) {
            if (_filterQuality != 'lossy') return false;
          }

          if (_filterFormat != null) {
            final ext = item.filePath.split('.').last.toLowerCase();
            if (ext != _filterFormat) return false;
          }

          if (_filterDateRange != null) {
            final now = DateTime.now();
            final itemDate = item.addedAt;
            switch (_filterDateRange) {
              case 'today':
                if (itemDate.year != now.year ||
                    itemDate.month != now.month ||
                    itemDate.day != now.day) {
                  return false;
                }
              case 'week':
                final weekAgo = now.subtract(const Duration(days: 7));
                if (itemDate.isBefore(weekAgo)) return false;
              case 'month':
                final monthAgo = DateTime(now.year, now.month - 1, now.day);
                if (itemDate.isBefore(monthAgo)) return false;
              case 'year':
                if (itemDate.year != now.year) return false;
            }
          }

          return true;
        })
        .toList(growable: false);
  }

  Set<String> _getAvailableFormats(List<UnifiedLibraryItem> items) {
    final formats = <String>{};
    for (final item in items) {
      final ext = item.filePath.split('.').last.toLowerCase();
      if (['flac', 'mp3', 'm4a', 'opus', 'ogg', 'wav', 'aiff'].contains(ext)) {
        formats.add(ext);
      }
    }
    return formats;
  }

  void _showFilterSheet(
    BuildContext context,
    List<UnifiedLibraryItem> allItems,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final availableFormats = _getAvailableFormats(allItems);

    String? tempSource = _filterSource;
    String? tempQuality = _filterQuality;
    String? tempFormat = _filterFormat;
    String? tempDateRange = _filterDateRange;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colorScheme.surfaceContainerLow,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 32,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  Row(
                    children: [
                      Text(
                        context.l10n.libraryFilterTitle,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Spacer(),
                      TextButton(
                        onPressed: () {
                          setSheetState(() {
                            tempSource = null;
                            tempQuality = null;
                            tempFormat = null;
                            tempDateRange = null;
                          });
                        },
                        child: Text(context.l10n.libraryFilterReset),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    context.l10n.libraryFilterSource,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: Text(context.l10n.libraryFilterAll),
                        selected: tempSource == null,
                        onSelected: (_) =>
                            setSheetState(() => tempSource = null),
                      ),
                      FilterChip(
                        label: Text(context.l10n.libraryFilterDownloaded),
                        selected: tempSource == 'downloaded',
                        onSelected: (_) =>
                            setSheetState(() => tempSource = 'downloaded'),
                      ),
                      FilterChip(
                        label: Text(context.l10n.libraryFilterLocal),
                        selected: tempSource == 'local',
                        onSelected: (_) =>
                            setSheetState(() => tempSource = 'local'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    context.l10n.libraryFilterQuality,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: Text(context.l10n.libraryFilterAll),
                        selected: tempQuality == null,
                        onSelected: (_) =>
                            setSheetState(() => tempQuality = null),
                      ),
                      FilterChip(
                        label: Text(context.l10n.libraryFilterQualityHiRes),
                        selected: tempQuality == 'hires',
                        onSelected: (_) =>
                            setSheetState(() => tempQuality = 'hires'),
                      ),
                      FilterChip(
                        label: Text(context.l10n.libraryFilterQualityCD),
                        selected: tempQuality == 'cd',
                        onSelected: (_) =>
                            setSheetState(() => tempQuality = 'cd'),
                      ),
                      FilterChip(
                        label: Text(context.l10n.libraryFilterQualityLossy),
                        selected: tempQuality == 'lossy',
                        onSelected: (_) =>
                            setSheetState(() => tempQuality = 'lossy'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    context.l10n.libraryFilterFormat,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: Text(context.l10n.libraryFilterAll),
                        selected: tempFormat == null,
                        onSelected: (_) =>
                            setSheetState(() => tempFormat = null),
                      ),
                      for (final format in availableFormats.toList()..sort())
                        FilterChip(
                          label: Text(format.toUpperCase()),
                          selected: tempFormat == format,
                          onSelected: (_) =>
                              setSheetState(() => tempFormat = format),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  Text(
                    context.l10n.libraryFilterDate,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: Text(context.l10n.libraryFilterAll),
                        selected: tempDateRange == null,
                        onSelected: (_) =>
                            setSheetState(() => tempDateRange = null),
                      ),
                      FilterChip(
                        label: Text(context.l10n.libraryFilterDateToday),
                        selected: tempDateRange == 'today',
                        onSelected: (_) =>
                            setSheetState(() => tempDateRange = 'today'),
                      ),
                      FilterChip(
                        label: Text(context.l10n.libraryFilterDateWeek),
                        selected: tempDateRange == 'week',
                        onSelected: (_) =>
                            setSheetState(() => tempDateRange = 'week'),
                      ),
                      FilterChip(
                        label: Text(context.l10n.libraryFilterDateMonth),
                        selected: tempDateRange == 'month',
                        onSelected: (_) =>
                            setSheetState(() => tempDateRange = 'month'),
                      ),
                      FilterChip(
                        label: Text(context.l10n.libraryFilterDateYear),
                        selected: tempDateRange == 'year',
                        onSelected: (_) =>
                            setSheetState(() => tempDateRange = 'year'),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),

                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        setState(() {
                          _filterSource = tempSource;
                          _filterQuality = tempQuality;
                          _filterFormat = tempFormat;
                          _filterDateRange = tempDateRange;
                          _unifiedItemsCache.clear();
                        });
                        Navigator.pop(context);
                      },
                      child: Text(context.l10n.libraryFilterApply),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _openFile(String filePath) async {
    final cleanPath = _cleanFilePath(filePath);
    try {
      await openFile(cleanPath);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(context.l10n.snackbarCannotOpenFile(e.toString())),
          ),
        );
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

  void _navigateToLocalMetadataScreen(LocalLibraryItem item) {
    _searchFocusNode.unfocus();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) =>
            TrackMetadataScreen(localItem: item),
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
        final searchKey = _searchIndexCache[item.id] ?? _buildSearchKey(item);
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

  _HistoryStats _buildHistoryStats(
    List<DownloadHistoryItem> items, [
    List<LocalLibraryItem> localItems = const [],
  ]) {
    final albumCounts = <String, int>{};
    final albumMap = <String, List<DownloadHistoryItem>>{};
    for (final item in items) {
      // Use lowercase key for case-insensitive grouping
      final key =
          '${item.albumName.toLowerCase()}|${(item.albumArtist ?? item.artistName).toLowerCase()}';
      albumCounts[key] = (albumCounts[key] ?? 0) + 1;
      albumMap.putIfAbsent(key, () => []).add(item);
    }

    int singleTracks = 0;
    for (final item in items) {
      final key =
          '${item.albumName.toLowerCase()}|${(item.albumArtist ?? item.artistName).toLowerCase()}';
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

      groupedAlbums.add(
        _GroupedAlbum(
          albumName: tracks.first.albumName,
          artistName: tracks.first.albumArtist ?? tracks.first.artistName,
          coverUrl: tracks.first.coverUrl,
          tracks: tracks,
          latestDownload: tracks
              .map((t) => t.downloadedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b),
        ),
      );
    });

    groupedAlbums.sort((a, b) => b.latestDownload.compareTo(a.latestDownload));

    int albumCount = 0;
    for (final count in albumCounts.values) {
      if (count > 1) albumCount++;
    }

    // Calculate local library stats
    final localAlbumCounts = <String, int>{};
    final localAlbumMap = <String, List<LocalLibraryItem>>{};
    for (final item in localItems) {
      final key =
          '${item.albumName.toLowerCase()}|${(item.albumArtist ?? item.artistName).toLowerCase()}';
      localAlbumCounts[key] = (localAlbumCounts[key] ?? 0) + 1;
      localAlbumMap.putIfAbsent(key, () => []).add(item);
    }

    int localAlbumCount = 0;
    int localSingleTracks = 0;
    for (final count in localAlbumCounts.values) {
      if (count > 1) {
        localAlbumCount++;
      } else {
        localSingleTracks++;
      }
    }

    // Build grouped local albums
    final groupedLocalAlbums = <_GroupedLocalAlbum>[];
    localAlbumMap.forEach((_, tracks) {
      if (tracks.length <= 1) return;
      tracks.sort((a, b) {
        final aNum = a.trackNumber ?? 999;
        final bNum = b.trackNumber ?? 999;
        return aNum.compareTo(bNum);
      });

      groupedLocalAlbums.add(
        _GroupedLocalAlbum(
          albumName: tracks.first.albumName,
          artistName: tracks.first.albumArtist ?? tracks.first.artistName,
          coverPath: tracks
              .firstWhere(
                (t) => t.coverPath != null && t.coverPath!.isNotEmpty,
                orElse: () => tracks.first,
              )
              .coverPath,
          tracks: tracks,
          latestScanned: tracks
              .map((t) => t.scannedAt)
              .reduce((a, b) => a.isAfter(b) ? a : b),
        ),
      );
    });

    groupedLocalAlbums.sort(
      (a, b) => b.latestScanned.compareTo(a.latestScanned),
    );

    return _HistoryStats(
      albumCounts: albumCounts,
      localAlbumCounts: localAlbumCounts,
      groupedAlbums: groupedAlbums,
      groupedLocalAlbums: groupedLocalAlbums,
      albumCount: albumCount,
      singleTracks: singleTracks,
      localAlbumCount: localAlbumCount,
      localSingleTracks: localSingleTracks,
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

  void _navigateToLocalAlbum(_GroupedLocalAlbum album) {
    _searchFocusNode.unfocus();
    Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) =>
            LocalAlbumScreen(
              albumName: album.albumName,
              artistName: album.artistName,
              coverPath: album.coverPath,
              tracks: album.tracks,
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
    // Watch local library items
    final localLibraryEnabled = ref.watch(
      settingsProvider.select((s) => s.localLibraryEnabled),
    );
    final localLibraryItems = localLibraryEnabled
        ? ref.watch(localLibraryProvider.select((s) => s.items))
        : const <LocalLibraryItem>[];

    _ensureHistoryCaches(allHistoryItems, localLibraryItems);
    final historyViewMode = ref.watch(
      settingsProvider.select((s) => s.historyViewMode),
    );
    final historyFilterMode = ref.watch(
      settingsProvider.select((s) => s.historyFilterMode),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = MediaQuery.of(context).padding.top;

    final historyStats =
        _historyStatsCache ??
        _buildHistoryStats(allHistoryItems, localLibraryItems);
    final groupedAlbums = historyStats.groupedAlbums;
    final groupedLocalAlbums = historyStats.groupedLocalAlbums;
    final albumCount = historyStats.totalAlbumCount;
    final singleCount = historyStats.totalSingleTracks;

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
            behavior: ScrollConfiguration.of(
              context,
            ).copyWith(overscroll: false),
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
                        titlePadding: const EdgeInsets.only(
                          left: 24,
                          bottom: 16,
                        ),
                        title: Text(
                          context.l10n.navLibrary,
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
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          _buildExportFailedButton(context, ref, colorScheme),
                          const SizedBox(width: 4),
                          _buildPauseResumeButton(context, ref, colorScheme),
                          const SizedBox(width: 4),
                          _buildClearAllButton(context, ref, colorScheme),
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

                if (allHistoryItems.isNotEmpty || localLibraryItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _FilterChip(
                              label: context.l10n.historyFilterAll,
                              count:
                                  allHistoryItems.length +
                                  localLibraryItems.length,
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
                  if (parentController == null ||
                      !parentController.hasClients) {
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
                      final currentPage =
                          parentController.page ??
                          widget.parentPageIndex.toDouble();
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
                            widget.nextPageIndex ??
                                (widget.parentPageIndex + 1),
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
                      groupedLocalAlbums: groupedLocalAlbums,
                      albumCounts: historyStats.albumCounts,
                      localAlbumCounts: historyStats.localAlbumCounts,
                      localLibraryItems: localLibraryItems,
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
              _buildUnifiedItemsForSelection(
                filterMode: historyFilterMode,
                allHistoryItems: allHistoryItems,
                albumCounts: historyStats.albumCounts,
                localLibraryItems: localLibraryItems,
                localAlbumCounts: historyStats.localAlbumCounts,
              ),
              bottomPadding,
            ),
          ),
        ],
      ),
    );
  }

  /// Build unified items list for selection mode
  List<UnifiedLibraryItem> _buildUnifiedItemsForSelection({
    required String filterMode,
    required List<DownloadHistoryItem> allHistoryItems,
    required Map<String, int> albumCounts,
    required List<LocalLibraryItem> localLibraryItems,
    required Map<String, int> localAlbumCounts,
  }) {
    final historyItems = _resolveHistoryItems(
      filterMode: filterMode,
      allHistoryItems: allHistoryItems,
      albumCounts: albumCounts,
    );

    final unifiedItems = _getUnifiedItems(
      filterMode: filterMode,
      historyItems: historyItems,
      localLibraryItems: localLibraryItems,
      localAlbumCounts: localAlbumCounts,
    );

    // Apply advanced filters to match what's displayed
    return _applyAdvancedFilters(unifiedItems);
  }

  List<UnifiedLibraryItem> _getUnifiedItems({
    required String filterMode,
    required List<DownloadHistoryItem> historyItems,
    required List<LocalLibraryItem> localLibraryItems,
    required Map<String, int> localAlbumCounts,
  }) {
    if (filterMode == 'albums') return const [];

    final query = _searchQuery;
    final cached = _unifiedItemsCache[filterMode];
    if (cached != null &&
        identical(cached.historyItems, historyItems) &&
        identical(cached.localItems, localLibraryItems) &&
        identical(cached.localAlbumCounts, localAlbumCounts) &&
        cached.query == query) {
      return cached.items;
    }

    final unifiedDownloaded = historyItems
        .map((item) => UnifiedLibraryItem.fromDownloadHistory(item))
        .toList(growable: false);

    List<LocalLibraryItem> localItemsForMerge;
    if (filterMode == 'all') {
      localItemsForMerge = _filterLocalItems(localLibraryItems, query);
    } else {
      final localSingles = localLibraryItems
          .where((item) {
            final count = localAlbumCounts[item.albumKey] ?? 0;
            return count == 1;
          })
          .toList(growable: false);
      localItemsForMerge = _filterLocalItems(localSingles, query);
    }

    final unifiedLocal = localItemsForMerge
        .map((item) => UnifiedLibraryItem.fromLocalLibrary(item))
        .toList(growable: false);

    final merged = <UnifiedLibraryItem>[...unifiedDownloaded, ...unifiedLocal]
      ..sort((a, b) => b.addedAt.compareTo(a.addedAt));

    _unifiedItemsCache[filterMode] = _UnifiedCacheEntry(
      historyItems: historyItems,
      localItems: localLibraryItems,
      localAlbumCounts: localAlbumCounts,
      query: query,
      items: merged,
    );

    return merged;
  }

  Widget _buildFilterContent({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String filterMode,
    required List<DownloadHistoryItem> allHistoryItems,
    required String historyViewMode,
    required List<DownloadItem> queueItems,
    required List<_GroupedAlbum> groupedAlbums,
    required List<_GroupedLocalAlbum> groupedLocalAlbums,
    required Map<String, int> albumCounts,
    required Map<String, int> localAlbumCounts,
    required List<LocalLibraryItem> localLibraryItems,
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

    // Filter local library albums based on search query
    final filteredGroupedLocalAlbums = searchQuery.isEmpty
        ? groupedLocalAlbums
        : groupedLocalAlbums
              .where((album) => album.searchKey.contains(searchQuery))
              .toList();

    // Total album count for display
    final totalAlbumCount =
        filteredGroupedAlbums.length + filteredGroupedLocalAlbums.length;

    final unifiedItems = _getUnifiedItems(
      filterMode: filterMode,
      historyItems: historyItems,
      localLibraryItems: localLibraryItems,
      localAlbumCounts: localAlbumCounts,
    );

    // Apply advanced filters
    final filteredUnifiedItems = _applyAdvancedFilters(unifiedItems);

    // Total count for display
    final totalTrackCount = filteredUnifiedItems.length;

    return CustomScrollView(
      slivers: [
        if (totalTrackCount > 0 && queueItems.isEmpty && filterMode != 'albums')
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    '$totalTrackCount ${totalTrackCount == 1 ? 'track' : 'tracks'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  // Filter button with long-press to reset
                  if (!_isSelectionMode)
                    GestureDetector(
                      onLongPress: _activeFilterCount > 0
                          ? _resetFilters
                          : null,
                      child: TextButton.icon(
                        onPressed: () =>
                            _showFilterSheet(context, unifiedItems),
                        icon: Badge(
                          isLabelVisible: _activeFilterCount > 0,
                          label: Text('$_activeFilterCount'),
                          child: const Icon(Icons.filter_list, size: 18),
                        ),
                        label: Text(context.l10n.libraryFilterTitle),
                        style: TextButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                        ),
                      ),
                    ),
                  if (!_isSelectionMode && filteredUnifiedItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: () =>
                          _enterSelectionMode(filteredUnifiedItems.first.id),
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

        if ((filteredGroupedAlbums.isNotEmpty ||
                filteredGroupedLocalAlbums.isNotEmpty) &&
            queueItems.isEmpty &&
            filterMode == 'albums')
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Text(
                '$totalAlbumCount ${totalAlbumCount == 1 ? 'album' : 'albums'}',
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
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

        // Combined albums grid (downloaded + local in single grid)
        if (filterMode == 'albums' &&
            (filteredGroupedAlbums.isNotEmpty ||
                filteredGroupedLocalAlbums.isNotEmpty))
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  // First render downloaded albums, then local albums
                  if (index < filteredGroupedAlbums.length) {
                    final album = filteredGroupedAlbums[index];
                    return KeyedSubtree(
                      key: ValueKey(album.key),
                      child: _buildAlbumGridItem(context, album, colorScheme),
                    );
                  } else {
                    final localIndex = index - filteredGroupedAlbums.length;
                    final album = filteredGroupedLocalAlbums[localIndex];
                    return KeyedSubtree(
                      key: ValueKey('local_${album.key}'),
                      child: _buildLocalAlbumGridItem(
                        context,
                        album,
                        colorScheme,
                      ),
                    );
                  }
                },
                childCount:
                    filteredGroupedAlbums.length +
                    filteredGroupedLocalAlbums.length,
              ),
            ),
          ),

        // Unified list for 'all' filter (merged downloaded + local)
        if (filteredUnifiedItems.isNotEmpty && filterMode == 'all')
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredUnifiedItems[index];
                      return KeyedSubtree(
                        key: ValueKey(item.id),
                        child: _buildUnifiedGridItem(
                          context,
                          item,
                          colorScheme,
                        ),
                      );
                    }, childCount: filteredUnifiedItems.length),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = filteredUnifiedItems[index];
                    return KeyedSubtree(
                      key: ValueKey(item.id),
                      child: _buildUnifiedLibraryItem(
                        context,
                        item,
                        colorScheme,
                      ),
                    );
                  }, childCount: filteredUnifiedItems.length),
                ),

        // Singles filter - show unified items (downloaded + local singles)
        if (filteredUnifiedItems.isNotEmpty && filterMode == 'singles')
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
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = filteredUnifiedItems[index];
                      return KeyedSubtree(
                        key: ValueKey(item.id),
                        child: _buildUnifiedGridItem(
                          context,
                          item,
                          colorScheme,
                        ),
                      );
                    }, childCount: filteredUnifiedItems.length),
                  ),
                )
              : SliverList(
                  delegate: SliverChildBuilderDelegate((context, index) {
                    final item = filteredUnifiedItems[index];
                    return KeyedSubtree(
                      key: ValueKey(item.id),
                      child: _buildUnifiedLibraryItem(
                        context,
                        item,
                        colorScheme,
                      ),
                    );
                  }, childCount: filteredUnifiedItems.length),
                ),

        if (queueItems.isEmpty &&
            totalTrackCount == 0 &&
            (filterMode != 'albums' ||
                (filteredGroupedAlbums.isEmpty &&
                    filteredGroupedLocalAlbums.isEmpty)) &&
            !showFilteringIndicator)
          SliverFillRemaining(
            hasScrollBody: false,
            child: _buildEmptyState(context, colorScheme, filterMode),
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
      icon: Icon(isPaused ? Icons.play_arrow : Icons.pause, size: 18),
      label: Text(
        isPaused ? context.l10n.actionResume : context.l10n.actionPause,
      ),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: isPaused
            ? colorScheme.primary
            : colorScheme.onSurfaceVariant,
      ),
    );
  }

  Widget _buildClearAllButton(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    return TextButton.icon(
      onPressed: () => _showClearAllDialog(context, ref, colorScheme),
      icon: const Icon(Icons.clear_all, size: 18),
      label: Text(context.l10n.queueClearAll),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: colorScheme.error,
      ),
    );
  }

  Widget _buildExportFailedButton(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) {
    final queueState = ref.watch(downloadQueueProvider);
    final failedCount = queueState.failedCount;

    if (failedCount == 0) {
      return const SizedBox.shrink();
    }

    return TextButton.icon(
      onPressed: () => _exportFailedDownloads(context, ref),
      icon: const Icon(Icons.file_download, size: 18),
      label: Text(context.l10n.queueExportFailed),
      style: TextButton.styleFrom(
        visualDensity: VisualDensity.compact,
        foregroundColor: colorScheme.tertiary,
      ),
    );
  }

  Future<void> _exportFailedDownloads(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final filePath = await ref
        .read(downloadQueueProvider.notifier)
        .exportFailedDownloads();

    if (!context.mounted) return;

    if (filePath != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.queueExportFailedSuccess),
          action: SnackBarAction(
            label: context.l10n.queueExportFailedClear,
            onPressed: () {
              ref.read(downloadQueueProvider.notifier).clearFailedDownloads();
            },
          ),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.queueExportFailedError),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  Future<void> _showClearAllDialog(
    BuildContext context,
    WidgetRef ref,
    ColorScheme colorScheme,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.queueClearAll),
        content: Text(context.l10n.queueClearAllMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: colorScheme.error),
            child: Text(context.l10n.dialogClear),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      ref.read(downloadQueueProvider.notifier).clearAll();
    }
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
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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

  /// Album grid item for local library albums
  Widget _buildLocalAlbumGridItem(
    BuildContext context,
    _GroupedLocalAlbum album,
    ColorScheme colorScheme,
  ) {
    return GestureDetector(
      onTap: () => _navigateToLocalAlbum(album),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: album.coverPath != null
                      ? Image.file(
                          File(album.coverPath!),
                          fit: BoxFit.cover,
                          width: double.infinity,
                          height: double.infinity,
                          cacheWidth: 300,
                          cacheHeight: 300,
                          errorBuilder: (context, error, stackTrace) =>
                              Container(
                                color: colorScheme.surfaceContainerHighest,
                                child: Center(
                                  child: Icon(
                                    Icons.album,
                                    color: colorScheme.onSurfaceVariant,
                                    size: 48,
                                  ),
                                ),
                              ),
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
                // "Local" badge instead of track count
                Positioned(
                  right: 8,
                  bottom: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: colorScheme.tertiaryContainer,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.folder,
                          size: 12,
                          color: colorScheme.onTertiaryContainer,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${album.tracks.length}',
                          style: TextStyle(
                            color: colorScheme.onTertiaryContainer,
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
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
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
    List<UnifiedLibraryItem> unifiedItems,
    double bottomPadding,
  ) {
    final selectedCount = _selectedIds.length;
    final allSelected =
        selectedCount == unifiedItems.length && unifiedItems.isNotEmpty;

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
                        _selectAll(unifiedItems);
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
                  onPressed: selectedCount > 0
                      ? () => _deleteSelected(unifiedItems)
                      : null,
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

  /// Build cover image widget for unified library item
  /// Supports network URLs (from downloads) and local file paths (from library scan)
  Widget _buildUnifiedCoverImage(
    UnifiedLibraryItem item,
    ColorScheme colorScheme,
    double size,
  ) {
    final isDownloaded = item.source == LibraryItemSource.downloaded;

    // Network URL cover (downloaded items)
    if (item.coverUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: item.coverUrl!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          memCacheWidth: (size * 2).toInt(),
          memCacheHeight: (size * 2).toInt(),
          cacheManager: CoverCacheManager.instance,
          placeholder: (context, url) => Container(
            width: size,
            height: size,
            color: colorScheme.surfaceContainerHighest,
            child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
          ),
          errorWidget: (context, url, error) => Container(
            width: size,
            height: size,
            color: colorScheme.surfaceContainerHighest,
            child: Icon(Icons.music_note, color: colorScheme.onSurfaceVariant),
          ),
        ),
      );
    }

    // Local file cover (from library scan)
    if (item.localCoverPath != null && item.localCoverPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(item.localCoverPath!),
          width: size,
          height: size,
          fit: BoxFit.cover,
          cacheWidth: (size * 2).toInt(),
          cacheHeight: (size * 2).toInt(),
          errorBuilder: (context, error, stackTrace) =>
              _buildPlaceholderCover(colorScheme, size, isDownloaded),
        ),
      );
    }

    // Placeholder (no cover)
    return _buildPlaceholderCover(colorScheme, size, isDownloaded);
  }

  /// Build placeholder cover image
  Widget _buildPlaceholderCover(
    ColorScheme colorScheme,
    double size,
    bool isDownloaded,
  ) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: isDownloaded
            ? colorScheme.surfaceContainerHighest
            : colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.music_note,
        color: isDownloaded
            ? colorScheme.onSurfaceVariant
            : colorScheme.onSecondaryContainer,
        size: size * 0.4,
      ),
    );
  }

  /// Build cover image for unified grid item (fills container)
  Widget _buildUnifiedGridCoverImage(
    UnifiedLibraryItem item,
    ColorScheme colorScheme,
  ) {
    final isDownloaded = item.source == LibraryItemSource.downloaded;

    // Network URL cover (downloaded items)
    if (item.coverUrl != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: CachedNetworkImage(
          imageUrl: item.coverUrl!,
          fit: BoxFit.cover,
          memCacheWidth: 200,
          memCacheHeight: 200,
          cacheManager: CoverCacheManager.instance,
          placeholder: (context, url) => Container(
            color: colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.music_note,
              color: colorScheme.onSurfaceVariant,
              size: 32,
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.music_note,
              color: colorScheme.onSurfaceVariant,
              size: 32,
            ),
          ),
        ),
      );
    }

    // Local file cover (from library scan)
    if (item.localCoverPath != null && item.localCoverPath!.isNotEmpty) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          File(item.localCoverPath!),
          fit: BoxFit.cover,
          cacheWidth: 200,
          cacheHeight: 200,
          errorBuilder: (context, error, stackTrace) => Container(
            color: colorScheme.secondaryContainer,
            child: Icon(
              Icons.music_note,
              color: colorScheme.onSecondaryContainer,
              size: 32,
            ),
          ),
        ),
      );
    }

    // Placeholder (no cover)
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: Container(
        color: isDownloaded
            ? colorScheme.surfaceContainerHighest
            : colorScheme.secondaryContainer,
        child: Icon(
          Icons.music_note,
          color: isDownloaded
              ? colorScheme.onSurfaceVariant
              : colorScheme.onSecondaryContainer,
          size: 32,
        ),
      ),
    );
  }

  /// Build a unified library item (merged downloaded + local)
  Widget _buildUnifiedLibraryItem(
    BuildContext context,
    UnifiedLibraryItem item,
    ColorScheme colorScheme,
  ) {
    final fileExists = _checkFileExists(item.filePath);
    final isSelected = _selectedIds.contains(item.id);
    final date = item.addedAt;
    final dateStr =
        '${_months[date.month - 1]} ${date.day}, ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';

    final isDownloaded = item.source == LibraryItemSource.downloaded;
    final sourceLabel = isDownloaded
        ? context.l10n.librarySourceDownloaded
        : context.l10n.librarySourceLocal;
    final sourceColor = isDownloaded
        ? colorScheme.primaryContainer
        : colorScheme.secondaryContainer;
    final sourceTextColor = isDownloaded
        ? colorScheme.onPrimaryContainer
        : colorScheme.onSecondaryContainer;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      color: isSelected
          ? colorScheme.primaryContainer.withValues(alpha: 0.3)
          : null,
      child: InkWell(
        onTap: _isSelectionMode
            ? () => _toggleSelection(item.id)
            : isDownloaded
            ? () => _navigateToHistoryMetadataScreen(item.historyItem!)
            : item.localItem != null
            ? () => _navigateToLocalMetadataScreen(item.localItem!)
            : () => _openFile(item.filePath),
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
              // Cover image - supports network URL and local file path
              _buildUnifiedCoverImage(item, colorScheme, 56),
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
                        // Source badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: sourceColor,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            sourceLabel,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: sourceTextColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                ),
                          ),
                        ),
                        const SizedBox(width: 8),
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
                            item.quality!.isNotEmpty) ...[
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
                        tooltip: context.l10n.tooltipPlay,
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

  /// Build unified grid item for grid view mode
  Widget _buildUnifiedGridItem(
    BuildContext context,
    UnifiedLibraryItem item,
    ColorScheme colorScheme,
  ) {
    final fileExists = _checkFileExists(item.filePath);
    final isSelected = _selectedIds.contains(item.id);
    final isDownloaded = item.source == LibraryItemSource.downloaded;

    return GestureDetector(
      onTap: _isSelectionMode
          ? () => _toggleSelection(item.id)
          : isDownloaded
          ? () => _navigateToHistoryMetadataScreen(item.historyItem!)
          : item.localItem != null
          ? () => _navigateToLocalMetadataScreen(item.localItem!)
          : () => _openFile(item.filePath),
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
                    child: _buildUnifiedGridCoverImage(item, colorScheme),
                  ),
                  // Source badge (top-right)
                  Positioned(
                    right: 4,
                    top: 4,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 4,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isDownloaded
                            ? colorScheme.primaryContainer
                            : colorScheme.secondaryContainer,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Icon(
                        isDownloaded ? Icons.download_done : Icons.folder,
                        size: 12,
                        color: isDownloaded
                            ? colorScheme.onPrimaryContainer
                            : colorScheme.onSecondaryContainer,
                      ),
                    ),
                  ),
                  // Quality badge (top-left)
                  if (item.quality != null && item.quality!.isNotEmpty)
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
                          _getQualityBadgeText(item.quality!),
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
