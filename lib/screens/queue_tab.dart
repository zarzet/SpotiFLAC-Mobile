import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/services/cover_cache_manager.dart';
import 'package:spotiflac_android/services/ffmpeg_service.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/l10n/l10n.dart';
import 'package:spotiflac_android/utils/app_bar_layout.dart';
import 'package:spotiflac_android/utils/file_access.dart';
import 'package:spotiflac_android/utils/lyrics_metadata_helper.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/providers/library_collections_provider.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/local_library_provider.dart';
import 'package:spotiflac_android/providers/playback_provider.dart';
import 'package:spotiflac_android/services/library_database.dart';
import 'package:spotiflac_android/services/history_database.dart';
import 'package:spotiflac_android/services/downloaded_embedded_cover_resolver.dart';
import 'package:spotiflac_android/screens/track_metadata_screen.dart';
import 'package:spotiflac_android/screens/downloaded_album_screen.dart';
import 'package:spotiflac_android/screens/library_tracks_folder_screen.dart';
import 'package:spotiflac_android/screens/local_album_screen.dart';

enum LibraryItemSource { downloaded, local }

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
    if (item.bitrate != null && item.bitrate! > 0) {
      // Lossy format with bitrate
      final fmt = item.format?.toUpperCase() ?? '';
      quality = '$fmt ${item.bitrate}kbps'.trim();
    } else if (item.bitDepth != null &&
        item.bitDepth! > 0 &&
        item.sampleRate != null) {
      // Lossless format with actual bit depth
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
      addedAt: item.fileModTime != null
          ? DateTime.fromMillisecondsSinceEpoch(item.fileModTime!)
          : item.scannedAt,
      source: LibraryItemSource.local,
      localItem: item,
    );
  }

  bool get hasCover =>
      coverUrl != null ||
      (localCoverPath != null && localCoverPath!.isNotEmpty);

  String get searchKey =>
      '${trackName.toLowerCase()}|${artistName.toLowerCase()}|${albumName.toLowerCase()}';
  String get albumKey =>
      '${albumName.toLowerCase()}|${artistName.toLowerCase()}';

  /// Returns the collection key used to match this item against playlist
  /// entries. Uses the same logic as [trackCollectionKey] from the collections
  /// provider: prefer ISRC, fall back to source:id.
  String get collectionKey {
    if (historyItem != null) {
      final isrc = historyItem!.isrc?.trim();
      if (isrc != null && isrc.isNotEmpty) return 'isrc:${isrc.toUpperCase()}';
      final source = historyItem!.service.trim().isNotEmpty
          ? historyItem!.service.trim()
          : 'builtin';
      return '$source:${historyItem!.id}';
    }
    if (localItem != null) {
      final isrc = localItem!.isrc?.trim();
      if (isrc != null && isrc.isNotEmpty) return 'isrc:${isrc.toUpperCase()}';
      return 'local:${localItem!.id}';
    }
    return 'builtin:$id';
  }

  /// Convert to a [Track] for adding to collections/playlists.
  Track toTrack() {
    if (historyItem != null) {
      final h = historyItem!;
      return Track(
        id: h.id,
        name: h.trackName,
        artistName: h.artistName,
        albumName: h.albumName,
        albumArtist: h.albumArtist,
        coverUrl: h.coverUrl,
        isrc: h.isrc,
        duration: h.duration ?? 0,
        trackNumber: h.trackNumber,
        discNumber: h.discNumber,
        releaseDate: h.releaseDate,
        source: h.service,
      );
    }
    if (localItem != null) {
      final l = localItem!;
      // Store coverPath (even local file paths) in coverUrl so playlist
      // entries retain the cover.  All renderers must check whether the
      // value is a URL or a local path and use the appropriate widget.
      return Track(
        id: l.id,
        name: l.trackName,
        artistName: l.artistName,
        albumName: l.albumName,
        albumArtist: l.albumArtist,
        coverUrl: l.coverPath,
        isrc: l.isrc,
        duration: l.duration ?? 0,
        trackNumber: l.trackNumber,
        discNumber: l.discNumber,
        releaseDate: l.releaseDate,
        source: 'local',
      );
    }
    // Fallback — should not happen
    return Track(
      id: id,
      name: trackName,
      artistName: artistName,
      albumName: albumName,
      coverUrl: coverUrl,
      duration: 0,
    );
  }
}

class _GroupedAlbum {
  final String albumName;
  final String artistName;
  final String? coverUrl;
  final String sampleFilePath;
  final List<DownloadHistoryItem> tracks;
  final DateTime latestDownload;
  final String searchKey;

  _GroupedAlbum({
    required this.albumName,
    required this.artistName,
    this.coverUrl,
    required this.sampleFilePath,
    required this.tracks,
    required this.latestDownload,
  }) : searchKey = '${albumName.toLowerCase()}|${artistName.toLowerCase()}';

  String get key => '$albumName|$artistName';
}

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

  int get totalAlbumCount => albumCount + localAlbumCount;

  int get totalSingleTracks => singleTracks + localSingleTracks;
}

class _FilterContentData {
  final List<DownloadHistoryItem> historyItems;
  final List<UnifiedLibraryItem> unifiedItems;
  final List<UnifiedLibraryItem> filteredUnifiedItems;
  final List<_GroupedAlbum> filteredGroupedAlbums;
  final List<_GroupedLocalAlbum> filteredGroupedLocalAlbums;
  final bool showFilteringIndicator;

  const _FilterContentData({
    required this.historyItems,
    required this.unifiedItems,
    required this.filteredUnifiedItems,
    required this.filteredGroupedAlbums,
    required this.filteredGroupedLocalAlbums,
    required this.showFilteringIndicator,
  });

  int get totalTrackCount => filteredUnifiedItems.length;
  int get totalAlbumCount =>
      filteredGroupedAlbums.length + filteredGroupedLocalAlbums.length;
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

class _QueueItemIdsSnapshot {
  final List<String> ids;

  const _QueueItemIdsSnapshot(this.ids);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is _QueueItemIdsSnapshot && listEquals(ids, other.ids);

  @override
  int get hashCode => Object.hashAll(ids);
}

Map<String, List<String>> _filterHistoryInIsolate(Map<String, Object> payload) {
  final entries = (payload['entries'] as List).cast<List>();
  final albumCounts = (payload['albumCounts'] as Map).cast<String, int>();
  final query = (payload['query'] as String?) ?? '';
  final hasQuery = query.isNotEmpty;

  final allIds = <String>[];
  final albumIds = <String>[];
  final singleIds = <String>[];

  for (final entry in entries) {
    final id = entry[0] as String;
    final albumKey = entry[1] as String;
    if (hasQuery) {
      final searchKey = entry[2] as String;
      if (!searchKey.contains(query)) {
        continue;
      }
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
  final Map<String, ValueNotifier<bool>> _fileExistsNotifiers = {};
  final ValueNotifier<bool> _alwaysMissingFileNotifier = ValueNotifier(false);
  final Set<String> _pendingChecks = {};
  static const int _maxCacheSize = 500;
  static const int _maxSearchIndexCacheSize = 4000;
  bool _embeddedCoverRefreshScheduled = false;

  bool _isSelectionMode = false;
  final Set<String> _selectedIds = {};

  bool _isPlaylistSelectionMode = false;
  final Set<String> _selectedPlaylistIds = {};

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
  String _sortMode = 'latest'; // 'latest', 'oldest', 'a-z', 'z-a'

  double _effectiveTextScale() {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    if (textScale < 1.0) return 1.0;
    if (textScale > 1.4) return 1.4;
    return textScale;
  }

  double _queueCoverSize() {
    final shortestSide = MediaQuery.sizeOf(context).shortestSide;
    final scale = (shortestSide / 390).clamp(0.82, 1.0);
    final textScale = _effectiveTextScale();
    return (56 * scale * (1 + ((textScale - 1) * 0.12))).clamp(46.0, 56.0);
  }

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
    for (final notifier in _fileExistsNotifiers.values) {
      notifier.dispose();
    }
    _fileExistsNotifiers.clear();
    _alwaysMissingFileNotifier.dispose();
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
    if (historyChanged) {
      _searchIndexCache.clear();
    }
    if (localChanged) {
      _localSearchIndexCache.clear();
      _localFilterItemsCache = null;
      _localFilterQueryCache = '';
      _filteredLocalItemsCache = const [];
    }
    _unifiedItemsCache.clear();

    if (historyChanged) {
      final validPaths = items
          .map((item) => _cleanFilePath(item.filePath))
          .where((path) => path.isNotEmpty)
          .toSet();
      DownloadedEmbeddedCoverResolver.invalidatePathsNotIn(validPaths);
    }
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

  String _historySearchKeyForItem(DownloadHistoryItem item) {
    final cached = _searchIndexCache[item.id];
    if (cached != null) return cached;

    final searchKey = _buildSearchKey(item);
    _searchIndexCache[item.id] = searchKey;
    while (_searchIndexCache.length > _maxSearchIndexCacheSize) {
      _searchIndexCache.remove(_searchIndexCache.keys.first);
    }
    return searchKey;
  }

  String _localSearchKeyForItem(LocalLibraryItem item) {
    final cached = _localSearchIndexCache[item.id];
    if (cached != null) return cached;

    final searchKey = _buildLocalSearchKey(item);
    _localSearchIndexCache[item.id] = searchKey;
    while (_localSearchIndexCache.length > _maxSearchIndexCacheSize) {
      _localSearchIndexCache.remove(_localSearchIndexCache.keys.first);
    }
    return searchKey;
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
          final searchKey = _localSearchKeyForItem(item);
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
    final includeSearchKey = query.isNotEmpty;
    final entries = List<List<String>>.generate(items.length, (index) {
      final item = items[index];
      final albumKey =
          '${item.albumName.toLowerCase()}|${(item.albumArtist ?? item.artistName).toLowerCase()}';
      if (!includeSearchKey) {
        return [item.id, albumKey];
      }
      final searchKey = _historySearchKeyForItem(item);
      return [item.id, albumKey, searchKey];
    }, growable: false);
    final payload = <String, Object>{
      'entries': entries,
      'albumCounts': albumCounts,
      'query': query,
    };

    compute(_filterHistoryInIsolate, payload).then((result) {
      if (!mounted || requestId != _filterRequestId) return;
      final itemsById = {for (final item in items) item.id: item};
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
          final searchKey = _historySearchKeyForItem(item);
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

  // --- Playlist selection mode ---

  void _enterPlaylistSelectionMode(String playlistId) {
    HapticFeedback.mediumImpact();
    setState(() {
      _isPlaylistSelectionMode = true;
      _selectedPlaylistIds.add(playlistId);
    });
  }

  void _exitPlaylistSelectionMode() {
    setState(() {
      _isPlaylistSelectionMode = false;
      _selectedPlaylistIds.clear();
    });
  }

  void _togglePlaylistSelection(String playlistId) {
    setState(() {
      if (_selectedPlaylistIds.contains(playlistId)) {
        _selectedPlaylistIds.remove(playlistId);
        if (_selectedPlaylistIds.isEmpty) {
          _isPlaylistSelectionMode = false;
        }
      } else {
        _selectedPlaylistIds.add(playlistId);
      }
    });
  }

  void _selectAllPlaylists(List<UserPlaylistCollection> playlists) {
    setState(() {
      _selectedPlaylistIds.addAll(playlists.map((e) => e.id));
    });
  }

  Future<void> _deleteSelectedPlaylists(BuildContext context) async {
    final count = _selectedPlaylistIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(ctx.l10n.collectionDeletePlaylist),
        content: Text(
          'Delete $count ${count == 1 ? 'playlist' : 'playlists'}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(ctx.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text(ctx.l10n.dialogDelete),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;

    final notifier = ref.read(libraryCollectionsProvider.notifier);
    for (final id in _selectedPlaylistIds.toList()) {
      await notifier.deletePlaylist(id);
    }

    if (!context.mounted) return;
    _exitPlaylistSelectionMode();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          '$count ${count == 1 ? 'playlist' : 'playlists'} deleted',
        ),
      ),
    );
  }

  Widget _buildPlaylistSelectionBottomBar(
    BuildContext context,
    ColorScheme colorScheme,
    List<UserPlaylistCollection> playlists,
    double bottomPadding,
  ) {
    final selectedCount = _selectedPlaylistIds.length;
    final allSelected =
        selectedCount == playlists.length && playlists.isNotEmpty;

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
                    onPressed: _exitPlaylistSelectionMode,
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
                              ? 'All playlists selected'
                              : 'Tap playlists to select',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),

                  TextButton.icon(
                    onPressed: () {
                      if (allSelected) {
                        _exitPlaylistSelectionMode();
                      } else {
                        _selectAllPlaylists(playlists);
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

              const SizedBox(height: 12),

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: selectedCount > 0
                      ? () => _deleteSelectedPlaylists(context)
                      : null,
                  icon: const Icon(Icons.delete_outline),
                  label: Text(
                    selectedCount > 0
                        ? 'Delete $selectedCount ${selectedCount == 1 ? 'playlist' : 'playlists'}'
                        : 'Select playlists to delete',
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

  String _getQualityBadgeText(String quality) {
    final q = quality.trim().toLowerCase();
    if (q.contains('bit')) {
      return quality.split('/').first;
    }

    // Supports "MP3 320k", "Opus 256kbps", etc.
    final bitrateTextMatch = RegExp(
      r'(\d+)\s*k(?:bps)?',
      caseSensitive: false,
    ).firstMatch(quality);
    if (bitrateTextMatch != null) {
      return '${bitrateTextMatch.group(1)}k';
    }

    // Supports legacy quality IDs like "opus_256" / "mp3_320".
    final bitrateIdMatch = RegExp(r'_(\d+)$').firstMatch(q);
    if (bitrateIdMatch != null) {
      return '${bitrateIdMatch.group(1)}k';
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
      final itemsById = {for (final item in allItems) item.id: item};

      int deletedCount = 0;
      for (final id in _selectedIds) {
        final item = itemsById[id];
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
    return DownloadedEmbeddedCoverResolver.cleanFilePath(filePath);
  }

  Future<int?> _readFileModTimeMillis(String? filePath) async {
    return DownloadedEmbeddedCoverResolver.readFileModTimeMillis(filePath);
  }

  void _onEmbeddedCoverChanged() {
    if (!mounted || _embeddedCoverRefreshScheduled) return;
    _embeddedCoverRefreshScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _embeddedCoverRefreshScheduled = false;
      if (mounted) {
        setState(() {});
      }
    });
  }

  Future<void> _scheduleDownloadedEmbeddedCoverRefreshForPath(
    String? filePath, {
    int? beforeModTime,
    bool force = false,
  }) async {
    await DownloadedEmbeddedCoverResolver.scheduleRefreshForPath(
      filePath,
      beforeModTime: beforeModTime,
      force: force,
      onChanged: _onEmbeddedCoverChanged,
    );
  }

  String? _resolveDownloadedEmbeddedCoverPath(String? filePath) {
    return DownloadedEmbeddedCoverResolver.resolve(
      filePath,
      onChanged: _onEmbeddedCoverChanged,
    );
  }

  ValueListenable<bool> _fileExistsListenable(String? filePath) {
    if (filePath == null) return _alwaysMissingFileNotifier;
    final cleanPath = _cleanFilePath(filePath);
    if (cleanPath.isEmpty) return _alwaysMissingFileNotifier;

    final existingNotifier = _fileExistsNotifiers[cleanPath];
    if (existingNotifier != null) {
      final cached = _fileExistsCache[cleanPath];
      if (cached != null && existingNotifier.value != cached) {
        existingNotifier.value = cached;
      } else if (cached == null) {
        _startFileExistsCheck(cleanPath);
      }
      return existingNotifier;
    }

    if (_fileExistsNotifiers.length >= _maxCacheSize) {
      final oldestKey = _fileExistsNotifiers.keys.first;
      _fileExistsNotifiers.remove(oldestKey)?.dispose();
      _fileExistsCache.remove(oldestKey);
    }

    final notifier = ValueNotifier<bool>(_fileExistsCache[cleanPath] ?? true);
    _fileExistsNotifiers[cleanPath] = notifier;
    _startFileExistsCheck(cleanPath);
    return notifier;
  }

  void _startFileExistsCheck(String cleanPath) {
    if (_pendingChecks.contains(cleanPath)) {
      return;
    }

    final cached = _fileExistsCache[cleanPath];
    if (cached != null) {
      final notifier = _fileExistsNotifiers[cleanPath];
      if (notifier != null && notifier.value != cached) {
        notifier.value = cached;
      }
      return;
    }

    _pendingChecks.add(cleanPath);
    Future.microtask(() async {
      final exists = await fileExists(cleanPath);
      _pendingChecks.remove(cleanPath);
      _fileExistsCache[cleanPath] = exists;
      final notifier = _fileExistsNotifiers[cleanPath];
      if (notifier != null && notifier.value != exists) {
        notifier.value = exists;
      }
    });
  }

  int get _activeFilterCount {
    int count = 0;
    if (_filterSource != null) count++;
    if (_filterQuality != null) count++;
    if (_filterFormat != null) count++;
    return count;
  }

  void _resetFilters() {
    setState(() {
      _filterSource = null;
      _filterQuality = null;
      _filterFormat = null;
      _sortMode = 'latest';
      _unifiedItemsCache.clear();
    });
  }

  String _fileExtLower(String filePath) {
    final dotIndex = filePath.lastIndexOf('.');
    if (dotIndex < 0 || dotIndex == filePath.length - 1) {
      return '';
    }
    return filePath.substring(dotIndex + 1).toLowerCase();
  }

  String? _localQualityLabel(LocalLibraryItem item) {
    if (item.bitrate != null && item.bitrate! > 0) {
      return '${item.bitrate}kbps';
    }
    if (item.bitDepth == null ||
        item.bitDepth == 0 ||
        item.sampleRate == null) {
      return null;
    }
    return '${item.bitDepth}bit/${(item.sampleRate! / 1000).toStringAsFixed(1)}kHz';
  }

  List<UnifiedLibraryItem> _applyAdvancedFilters(
    List<UnifiedLibraryItem> items,
  ) {
    List<UnifiedLibraryItem> filtered;
    if (_activeFilterCount == 0) {
      filtered = items;
    } else {
      filtered = items
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
              final ext = _fileExtLower(item.filePath);
              if (ext != _filterFormat) return false;
            }

            return true;
          })
          .toList(growable: false);
    }

    // Apply sorting
    return _applySorting(filtered);
  }

  List<UnifiedLibraryItem> _applySorting(List<UnifiedLibraryItem> items) {
    if (_sortMode == 'latest') {
      return items; // Already sorted newest first from _getUnifiedItems
    }
    final sorted = List<UnifiedLibraryItem>.of(items);
    switch (_sortMode) {
      case 'oldest':
        sorted.sort((a, b) => a.addedAt.compareTo(b.addedAt));
      case 'a-z':
        sorted.sort(
          (a, b) =>
              a.trackName.toLowerCase().compareTo(b.trackName.toLowerCase()),
        );
      case 'z-a':
        sorted.sort(
          (a, b) =>
              b.trackName.toLowerCase().compareTo(a.trackName.toLowerCase()),
        );
    }
    return sorted;
  }

  bool _passesQualityFilter(String? quality) {
    if (_filterQuality == null) return true;
    if (quality == null) return _filterQuality == 'lossy';
    final q = quality.toLowerCase();
    switch (_filterQuality) {
      case 'hires':
        return q.startsWith('24');
      case 'cd':
        return q.startsWith('16');
      case 'lossy':
        return !q.startsWith('24') && !q.startsWith('16');
      default:
        return true;
    }
  }

  bool _passesFormatFilter(String filePath) {
    if (_filterFormat == null) return true;
    return _fileExtLower(filePath) == _filterFormat;
  }

  List<_GroupedAlbum> _filterGroupedAlbums(
    List<_GroupedAlbum> albums,
    String searchQuery,
  ) {
    if (_activeFilterCount == 0 &&
        searchQuery.isEmpty &&
        _sortMode == 'latest') {
      return albums;
    }

    // Source filter: if filtering local only, hide all download albums
    if (_filterSource == 'local') return const [];

    final result = <_GroupedAlbum>[];
    for (final album in albums) {
      if (searchQuery.isNotEmpty && !album.searchKey.contains(searchQuery)) {
        continue;
      }

      // Filter tracks within the album by advanced filters
      if (_filterQuality != null || _filterFormat != null) {
        var hasMatchingTrack = false;
        for (final track in album.tracks) {
          if (!_passesQualityFilter(track.quality)) continue;
          if (!_passesFormatFilter(track.filePath)) continue;
          hasMatchingTrack = true;
          break;
        }

        if (!hasMatchingTrack) continue;
      }

      result.add(album);
    }

    // Apply sorting to albums
    switch (_sortMode) {
      case 'oldest':
        result.sort((a, b) => a.latestDownload.compareTo(b.latestDownload));
      case 'a-z':
        result.sort(
          (a, b) =>
              a.albumName.toLowerCase().compareTo(b.albumName.toLowerCase()),
        );
      case 'z-a':
        result.sort(
          (a, b) =>
              b.albumName.toLowerCase().compareTo(a.albumName.toLowerCase()),
        );
      default: // 'latest' - already sorted
        break;
    }

    return result;
  }

  List<_GroupedLocalAlbum> _filterGroupedLocalAlbums(
    List<_GroupedLocalAlbum> albums,
    String searchQuery,
  ) {
    if (_activeFilterCount == 0 &&
        searchQuery.isEmpty &&
        _sortMode == 'latest') {
      return albums;
    }

    // Source filter: if filtering downloaded only, hide all local albums
    if (_filterSource == 'downloaded') return const [];

    final result = <_GroupedLocalAlbum>[];
    for (final album in albums) {
      if (searchQuery.isNotEmpty && !album.searchKey.contains(searchQuery)) {
        continue;
      }

      // Filter tracks within the album by advanced filters
      if (_filterQuality != null || _filterFormat != null) {
        var hasMatchingTrack = false;
        for (final track in album.tracks) {
          if (!_passesQualityFilter(_localQualityLabel(track))) continue;
          if (!_passesFormatFilter(track.filePath)) continue;
          hasMatchingTrack = true;
          break;
        }

        if (!hasMatchingTrack) continue;
      }

      result.add(album);
    }

    // Apply sorting to local albums
    switch (_sortMode) {
      case 'oldest':
        result.sort((a, b) => a.latestScanned.compareTo(b.latestScanned));
      case 'a-z':
        result.sort(
          (a, b) =>
              a.albumName.toLowerCase().compareTo(b.albumName.toLowerCase()),
        );
      case 'z-a':
        result.sort(
          (a, b) =>
              b.albumName.toLowerCase().compareTo(a.albumName.toLowerCase()),
        );
      default: // 'latest' - already sorted
        break;
    }

    return result;
  }

  Set<String> _getAvailableFormats(List<UnifiedLibraryItem> items) {
    final formats = <String>{};
    for (final item in items) {
      final ext = _fileExtLower(item.filePath);
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
    String tempSortMode = _sortMode;

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
                            tempSortMode = 'latest';
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
                    context.l10n.libraryFilterSort,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: Text(context.l10n.libraryFilterSortLatest),
                        selected: tempSortMode == 'latest',
                        onSelected: (_) =>
                            setSheetState(() => tempSortMode = 'latest'),
                      ),
                      FilterChip(
                        label: Text(context.l10n.libraryFilterSortOldest),
                        selected: tempSortMode == 'oldest',
                        onSelected: (_) =>
                            setSheetState(() => tempSortMode = 'oldest'),
                      ),
                      FilterChip(
                        label: const Text('A-Z'),
                        selected: tempSortMode == 'a-z',
                        onSelected: (_) =>
                            setSheetState(() => tempSortMode = 'a-z'),
                      ),
                      FilterChip(
                        label: const Text('Z-A'),
                        selected: tempSortMode == 'z-a',
                        onSelected: (_) =>
                            setSheetState(() => tempSortMode = 'z-a'),
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
                          _sortMode = tempSortMode;
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

  Future<void> _openFile(
    String filePath, {
    String title = '',
    String artist = '',
    String album = '',
    String coverUrl = '',
  }) async {
    final cleanPath = _cleanFilePath(filePath);
    try {
      final fallbackTitle = cleanPath.split('/').last.split('\\').last;
      await ref
          .read(playbackProvider.notifier)
          .playLocalPath(
            path: cleanPath,
            title: title.isNotEmpty ? title : fallbackTitle,
            artist: artist,
            album: album,
            coverUrl: coverUrl,
          );
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
    final dpr = MediaQuery.devicePixelRatioOf(
      context,
    ).clamp(1.0, 3.0).toDouble();
    final targetSize = (360 * dpr).round().clamp(512, 1024).toInt();
    precacheImage(
      ResizeImage(
        CachedNetworkImageProvider(
          url,
          cacheManager: CoverCacheManager.instance,
        ),
        width: targetSize,
        height: targetSize,
      ),
      context,
    );
  }

  Future<void> _navigateToMetadataScreen(DownloadItem item) async {
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

    final navigator = Navigator.of(context);
    _precacheCover(historyItem.coverUrl);
    _searchFocusNode.unfocus();
    final beforeModTime = await _readFileModTimeMillis(historyItem.filePath);
    if (!mounted) return;
    final result = await navigator.push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) =>
            TrackMetadataScreen(item: historyItem),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    _searchFocusNode.unfocus();
    if (result == true) {
      await _scheduleDownloadedEmbeddedCoverRefreshForPath(
        historyItem.filePath,
        beforeModTime: beforeModTime,
        force: true,
      );
      return;
    }
    await _scheduleDownloadedEmbeddedCoverRefreshForPath(
      historyItem.filePath,
      beforeModTime: beforeModTime,
    );
  }

  Future<void> _navigateToHistoryMetadataScreen(
    DownloadHistoryItem item,
  ) async {
    final navigator = Navigator.of(context);
    _precacheCover(item.coverUrl);
    _searchFocusNode.unfocus();
    final beforeModTime = await _readFileModTimeMillis(item.filePath);
    if (!mounted) return;
    final result = await navigator.push(
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 300),
        reverseTransitionDuration: const Duration(milliseconds: 250),
        pageBuilder: (context, animation, secondaryAnimation) =>
            TrackMetadataScreen(item: item),
        transitionsBuilder: (context, animation, secondaryAnimation, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
    _searchFocusNode.unfocus();
    if (result == true) {
      await _scheduleDownloadedEmbeddedCoverRefreshForPath(
        item.filePath,
        beforeModTime: beforeModTime,
        force: true,
      );
      return;
    }
    await _scheduleDownloadedEmbeddedCoverRefreshForPath(
      item.filePath,
      beforeModTime: beforeModTime,
    );
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
        final searchKey = _historySearchKeyForItem(item);
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
          sampleFilePath: tracks.first.filePath,
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

  void _openWishlistFolder() {
    _searchFocusNode.unfocus();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => const LibraryTracksFolderScreen(
              mode: LibraryTracksFolderMode.wishlist,
            ),
          ),
        )
        .then((_) => _searchFocusNode.unfocus());
  }

  void _openLovedFolder() {
    _searchFocusNode.unfocus();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => const LibraryTracksFolderScreen(
              mode: LibraryTracksFolderMode.loved,
            ),
          ),
        )
        .then((_) => _searchFocusNode.unfocus());
  }

  void _openPlaylistById(String playlistId) {
    _searchFocusNode.unfocus();
    Navigator.of(context)
        .push(
          MaterialPageRoute(
            builder: (_) => LibraryTracksFolderScreen(
              mode: LibraryTracksFolderMode.playlist,
              playlistId: playlistId,
            ),
          ),
        )
        .then((_) => _searchFocusNode.unfocus());
  }

  Future<void> _showCreatePlaylistDialog(BuildContext context) async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final playlistName = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text(dialogContext.l10n.collectionCreatePlaylist),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: controller,
              autofocus: true,
              decoration: InputDecoration(
                hintText: dialogContext.l10n.collectionPlaylistNameHint,
              ),
              validator: (value) {
                final trimmed = value?.trim() ?? '';
                if (trimmed.isEmpty) {
                  return dialogContext.l10n.collectionPlaylistNameRequired;
                }
                return null;
              },
              onFieldSubmitted: (_) {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: Text(dialogContext.l10n.dialogCancel),
            ),
            FilledButton(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                Navigator.of(dialogContext).pop(controller.text.trim());
              },
              child: Text(dialogContext.l10n.actionCreate),
            ),
          ],
        );
      },
    );

    if (playlistName == null || playlistName.isEmpty) return;
    await ref
        .read(libraryCollectionsProvider.notifier)
        .createPlaylist(playlistName);
  }

  /// Build a playlist cover thumbnail (custom cover > first track cover > icon fallback).
  /// Pass a finite [size] (e.g. 56) for list view, or `null` for grid view
  /// where the widget should expand to fill its parent.
  Widget _buildPlaylistCover(
    UserPlaylistCollection playlist,
    ColorScheme colorScheme, [
    double? size,
  ]) {
    final borderRadius = BorderRadius.circular(8);

    final customCoverPath = playlist.coverImagePath;
    if (customCoverPath != null && customCoverPath.isNotEmpty) {
      return ClipRRect(
        borderRadius: borderRadius,
        child: Image.file(
          File(customCoverPath),
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _playlistIconFallback(colorScheme, size),
        ),
      );
    }

    final firstCoverUrl = playlist.tracks
        .where((e) => e.track.coverUrl != null && e.track.coverUrl!.isNotEmpty)
        .map((e) => e.track.coverUrl!)
        .firstOrNull;

    if (firstCoverUrl != null) {
      // Guard against local file paths that may have been stored as coverUrl
      final isLocalPath =
          !firstCoverUrl.startsWith('http://') &&
          !firstCoverUrl.startsWith('https://');
      if (isLocalPath) {
        return ClipRRect(
          borderRadius: borderRadius,
          child: Image.file(
            File(firstCoverUrl),
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _playlistIconFallback(colorScheme, size),
          ),
        );
      }
      return ClipRRect(
        borderRadius: borderRadius,
        child: CachedNetworkImage(
          imageUrl: firstCoverUrl,
          width: size,
          height: size,
          fit: BoxFit.cover,
          placeholder: (_, _) => _playlistIconFallback(colorScheme, size),
          errorWidget: (_, _, _) => _playlistIconFallback(colorScheme, size),
        ),
      );
    }

    return _playlistIconFallback(colorScheme, size);
  }

  /// Icon fallback for playlists with no cover.
  /// When [size] is null the container expands to fill its parent (grid view)
  /// and uses a fixed icon size.
  Widget _playlistIconFallback(ColorScheme colorScheme, [double? size]) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFF5085A5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        Icons.queue_music,
        color: Colors.white,
        size: size != null ? size * 0.5 : 40,
      ),
    );
  }

  /// Handle a track being dropped onto a playlist.
  /// When selection mode is active and the dragged item is among the selected,
  /// all selected tracks are added to the playlist.
  Future<void> _onTrackDroppedOnPlaylist(
    BuildContext context,
    UnifiedLibraryItem item,
    String playlistId,
    String playlistName, {
    List<UnifiedLibraryItem> allItems = const [],
  }) async {
    final notifier = ref.read(libraryCollectionsProvider.notifier);

    // If in selection mode and the dragged item is selected, add ALL selected
    if (_isSelectionMode &&
        _selectedIds.isNotEmpty &&
        _selectedIds.contains(item.id)) {
      final selectedItems = allItems
          .where((e) => _selectedIds.contains(e.id))
          .toList();
      // Fallback: if allItems is empty or no match, at least add the dragged item
      if (selectedItems.isEmpty) {
        selectedItems.add(item);
      }

      final batchResult = await notifier.addTracksToPlaylist(
        playlistId,
        selectedItems.map((selected) => selected.toTrack()),
      );
      final addedCount = batchResult.addedCount;
      final alreadyCount = batchResult.alreadyInPlaylistCount;

      if (!context.mounted) return;
      final message = addedCount > 0
          ? 'Added $addedCount ${addedCount == 1 ? 'track' : 'tracks'} to $playlistName'
                '${alreadyCount > 0 ? ' ($alreadyCount already in playlist)' : ''}'
          : context.l10n.collectionAlreadyInPlaylist(playlistName);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
      _exitSelectionMode();
      return;
    }

    // Single track drop
    final track = item.toTrack();
    final added = await notifier.addTrackToPlaylist(playlistId, track);

    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added
              ? context.l10n.collectionAddedToPlaylist(playlistName)
              : context.l10n.collectionAlreadyInPlaylist(playlistName),
        ),
      ),
    );
  }

  /// Build a compact floating feedback widget shown while dragging a track.
  /// Shows the count when multiple tracks are selected and being dragged.
  Widget _buildDragFeedback(
    BuildContext context,
    UnifiedLibraryItem item,
    ColorScheme colorScheme,
  ) {
    final isDraggingMultiple =
        _isSelectionMode &&
        _selectedIds.contains(item.id) &&
        _selectedIds.length > 1;
    final count = isDraggingMultiple ? _selectedIds.length : 1;

    return Material(
      elevation: 6,
      borderRadius: BorderRadius.circular(12),
      color: colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.playlist_add, size: 18, color: colorScheme.primary),
            const SizedBox(width: 8),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                isDraggingMultiple ? '$count tracks' : item.trackName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    _initializePageController();

    final hasQueueItems = ref.watch(
      downloadQueueLookupProvider.select((lookup) => lookup.itemIds.isNotEmpty),
    );
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
    final collectionState = ref.watch(libraryCollectionsProvider);

    _ensureHistoryCaches(allHistoryItems, localLibraryItems);
    final historyViewMode = ref.watch(
      settingsProvider.select((s) => s.historyViewMode),
    );
    final historyFilterMode = ref.watch(
      settingsProvider.select((s) => s.historyFilterMode),
    );
    final colorScheme = Theme.of(context).colorScheme;
    final topPadding = normalizedHeaderTopPadding(context);

    final historyStats =
        _historyStatsCache ??
        _buildHistoryStats(allHistoryItems, localLibraryItems);
    final groupedAlbums = historyStats.groupedAlbums;
    final groupedLocalAlbums = historyStats.groupedLocalAlbums;
    final filteredGroupedAlbums = _filterGroupedAlbums(
      groupedAlbums,
      _searchQuery,
    );
    final filteredGroupedLocalAlbums = _filterGroupedLocalAlbums(
      groupedLocalAlbums,
      _searchQuery,
    );
    final albumCount = historyStats.totalAlbumCount;
    final singleCount = historyStats.totalSingleTracks;
    final filterDataCache = <String, _FilterContentData>{};

    _FilterContentData getFilterData(String filterMode) {
      return filterDataCache.putIfAbsent(
        filterMode,
        () => _computeFilterContentData(
          filterMode: filterMode,
          allHistoryItems: allHistoryItems,
          filteredGroupedAlbums: filteredGroupedAlbums,
          filteredGroupedLocalAlbums: filteredGroupedLocalAlbums,
          albumCounts: historyStats.albumCounts,
          localAlbumCounts: historyStats.localAlbumCounts,
          localLibraryItems: localLibraryItems,
          collectionState: collectionState,
        ),
      );
    }

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
                if (allHistoryItems.isNotEmpty ||
                    hasQueueItems ||
                    localLibraryItems.isNotEmpty)
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

                if (hasQueueItems)
                  _buildQueueHeaderSliver(context, colorScheme),

                if (hasQueueItems) _buildQueueItemsSliver(context, colorScheme),

                if (allHistoryItems.isNotEmpty || localLibraryItems.isNotEmpty)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Builder(
                        builder: (context) {
                          // Compute filtered counts for tab chips
                          int filteredAllCount;
                          int filteredAlbumCount;
                          int filteredSingleCount;

                          if (_activeFilterCount == 0 && _searchQuery.isEmpty) {
                            filteredAllCount =
                                allHistoryItems.length +
                                localLibraryItems.length;
                            filteredAlbumCount = albumCount;
                            filteredSingleCount = singleCount;
                          } else {
                            final allData = getFilterData('all');
                            final albumsData = getFilterData('albums');
                            final singlesData = getFilterData('singles');
                            filteredAllCount = allData.totalTrackCount;
                            filteredAlbumCount = albumsData.totalAlbumCount;
                            filteredSingleCount = singlesData.totalTrackCount;
                          }

                          return SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: context.l10n.historyFilterAll,
                                  count: filteredAllCount,
                                  isSelected: historyFilterMode == 'all',
                                  onTap: () {
                                    _animateToFilterPage(0);
                                  },
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: context.l10n.historyFilterAlbums,
                                  count: filteredAlbumCount,
                                  isSelected: historyFilterMode == 'albums',
                                  onTap: () {
                                    _animateToFilterPage(1);
                                  },
                                ),
                                const SizedBox(width: 8),
                                _FilterChip(
                                  label: context.l10n.historyFilterSingles,
                                  count: filteredSingleCount,
                                  isSelected: historyFilterMode == 'singles',
                                  onTap: () {
                                    _animateToFilterPage(2);
                                  },
                                ),
                              ],
                            ),
                          );
                        },
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
                    final filterData = getFilterData(filterMode);
                    return _buildFilterContent(
                      context: context,
                      colorScheme: colorScheme,
                      filterMode: filterMode,
                      historyViewMode: historyViewMode,
                      hasQueueItems: hasQueueItems,
                      filterData: filterData,
                      localLibraryItems: localLibraryItems,
                      collectionState: collectionState,
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
            child: _isSelectionMode
                ? _buildSelectionBottomBar(
                    context,
                    colorScheme,
                    _buildUnifiedItemsForSelection(
                      filterMode: historyFilterMode,
                      allHistoryItems: allHistoryItems,
                      albumCounts: historyStats.albumCounts,
                      localLibraryItems: localLibraryItems,
                      localAlbumCounts: historyStats.localAlbumCounts,
                      collectionState: collectionState,
                    ),
                    bottomPadding,
                  )
                : const SizedBox.shrink(),
          ),

          // Playlist selection bottom bar
          AnimatedPositioned(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOutCubic,
            left: 0,
            right: 0,
            bottom: _isPlaylistSelectionMode ? 0 : -(200 + bottomPadding),
            child: _isPlaylistSelectionMode
                ? _buildPlaylistSelectionBottomBar(
                    context,
                    colorScheme,
                    collectionState.playlists,
                    bottomPadding,
                  )
                : const SizedBox.shrink(),
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
    required LibraryCollectionsState collectionState,
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
    final filtered = _applyAdvancedFilters(unifiedItems);

    if (!collectionState.hasPlaylistTracks) return filtered;
    return filtered
        .where(
          (item) => !collectionState.isTrackInAnyPlaylist(item.collectionKey),
        )
        .toList(growable: false);
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

  _FilterContentData _computeFilterContentData({
    required String filterMode,
    required List<DownloadHistoryItem> allHistoryItems,
    required List<_GroupedAlbum> filteredGroupedAlbums,
    required List<_GroupedLocalAlbum> filteredGroupedLocalAlbums,
    required Map<String, int> albumCounts,
    required Map<String, int> localAlbumCounts,
    required List<LocalLibraryItem> localLibraryItems,
    required LibraryCollectionsState collectionState,
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

    final unifiedItems = _getUnifiedItems(
      filterMode: filterMode,
      historyItems: historyItems,
      localLibraryItems: localLibraryItems,
      localAlbumCounts: localAlbumCounts,
    );
    final filtered = _applyAdvancedFilters(unifiedItems);

    // Remove tracks that are already in any playlist so they don't appear
    // in the main tracks list.  When a track is removed from a playlist (or
    // the playlist is deleted) it will automatically reappear here because it
    // will no longer be in the set.
    final filteredUnifiedItems = !collectionState.hasPlaylistTracks
        ? filtered
        : filtered
              .where(
                (item) =>
                    !collectionState.isTrackInAnyPlaylist(item.collectionKey),
              )
              .toList(growable: false);

    return _FilterContentData(
      historyItems: historyItems,
      unifiedItems: unifiedItems,
      filteredUnifiedItems: filteredUnifiedItems,
      filteredGroupedAlbums: filteredGroupedAlbums,
      filteredGroupedLocalAlbums: filteredGroupedLocalAlbums,
      showFilteringIndicator: showFilteringIndicator,
    );
  }

  Widget _buildQueueHeaderSliver(
    BuildContext context,
    ColorScheme colorScheme,
  ) {
    return Consumer(
      builder: (context, ref, child) {
        final queueCount = ref.watch(
          downloadQueueLookupProvider.select((lookup) => lookup.itemIds.length),
        );
        if (queueCount == 0) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Text(
                  'Downloading ($queueCount)',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                _buildPauseResumeButton(context, ref, colorScheme),
                const SizedBox(width: 4),
                _buildClearAllButton(context, ref, colorScheme),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueueItemsSliver(BuildContext context, ColorScheme colorScheme) {
    return Consumer(
      builder: (context, ref, child) {
        final queueIdsSnapshot = ref.watch(
          downloadQueueLookupProvider.select(
            (lookup) => _QueueItemIdsSnapshot(lookup.itemIds),
          ),
        );
        if (queueIdsSnapshot.ids.isEmpty) {
          return const SliverToBoxAdapter(child: SizedBox.shrink());
        }
        return SliverList(
          delegate: SliverChildBuilderDelegate((context, index) {
            final itemId = queueIdsSnapshot.ids[index];
            return _QueueItemSliverRow(
              key: ValueKey(itemId),
              itemId: itemId,
              colorScheme: colorScheme,
              itemBuilder: _buildQueueItem,
            );
          }, childCount: queueIdsSnapshot.ids.length),
        );
      },
    );
  }

  /// Build a Spotify-style collection list item (Wishlist, Loved, Playlists)
  Widget _buildCollectionListItem({
    required BuildContext context,
    required ColorScheme colorScheme,
    IconData? icon,
    Color? iconColor,
    Color? iconBgColor,
    Widget? coverWidget,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final cover =
        coverWidget ??
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: iconBgColor ?? colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon ?? Icons.folder,
            color: iconColor ?? Colors.white,
            size: 28,
          ),
        );

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox(width: 56, height: 56, child: cover),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: colorScheme.onSurfaceVariant,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Build a collection grid item for grid view mode
  Widget _buildCollectionGridItem({
    required BuildContext context,
    required ColorScheme colorScheme,
    IconData? icon,
    Color? iconColor,
    Color? iconBgColor,
    Widget? coverWidget,
    required String title,
    required int count,
    required VoidCallback onTap,
    VoidCallback? onLongPress,
  }) {
    final cover =
        coverWidget ??
        Container(
          decoration: BoxDecoration(
            color: iconBgColor ?? colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon ?? Icons.folder,
            color: iconColor ?? Colors.white,
            size: 40,
          ),
        );

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: cover,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w500),
          ),
          Text(
            '$count ${count == 1 ? 'item' : 'items'}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  /// Build a collection item at [index] for the unified "All" tab grid view.
  /// Index 0 = Wishlist, 1 = Loved, 2+ = individual playlists.
  Widget _buildAllTabGridCollectionItem({
    required BuildContext context,
    required ColorScheme colorScheme,
    required int index,
    required LibraryCollectionsState collectionState,
    List<UnifiedLibraryItem> filteredUnifiedItems = const [],
  }) {
    if (index == 0) {
      return _buildCollectionGridItem(
        context: context,
        colorScheme: colorScheme,
        icon: Icons.add_circle_outline,
        iconColor: Colors.white,
        iconBgColor: const Color(0xFF1DB954),
        title: context.l10n.collectionWishlist,
        count: collectionState.wishlistCount,
        onTap: _openWishlistFolder,
      );
    } else if (index == 1) {
      return _buildCollectionGridItem(
        context: context,
        colorScheme: colorScheme,
        icon: Icons.favorite,
        iconColor: Colors.white,
        iconBgColor: const Color(0xFF8C67AC),
        title: context.l10n.collectionLoved,
        count: collectionState.lovedCount,
        onTap: _openLovedFolder,
      );
    } else {
      final playlist = collectionState.playlists[index - 2];
      final isSelected = _selectedPlaylistIds.contains(playlist.id);
      return DragTarget<UnifiedLibraryItem>(
        onWillAcceptWithDetails: (_) => !_isPlaylistSelectionMode,
        onAcceptWithDetails: (details) {
          _onTrackDroppedOnPlaylist(
            context,
            details.data,
            playlist.id,
            playlist.name,
            allItems: filteredUnifiedItems,
          );
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: isHovering
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary, width: 2),
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  )
                : null,
            child: Stack(
              children: [
                _buildCollectionGridItem(
                  context: context,
                  colorScheme: colorScheme,
                  coverWidget: _buildPlaylistCover(playlist, colorScheme),
                  title: playlist.name,
                  count: playlist.tracks.length,
                  onTap: _isPlaylistSelectionMode
                      ? () => _togglePlaylistSelection(playlist.id)
                      : () => _openPlaylistById(playlist.id),
                  onLongPress: _isPlaylistSelectionMode
                      ? () => _togglePlaylistSelection(playlist.id)
                      : () => _enterPlaylistSelectionMode(playlist.id),
                ),
                if (_isPlaylistSelectionMode)
                  Positioned(
                    left: 0,
                    top: 0,
                    right: 0,
                    child: AspectRatio(
                      aspectRatio: 1,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isSelected
                              ? colorScheme.primary.withValues(alpha: 0.3)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                if (_isPlaylistSelectionMode)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      decoration: BoxDecoration(
                        color: isSelected
                            ? colorScheme.primary
                            : colorScheme.surface.withValues(alpha: 0.85),
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
                              size: 16,
                              color: colorScheme.onPrimary,
                            )
                          : const SizedBox(width: 16, height: 16),
                    ),
                  ),
              ],
            ),
          );
        },
      );
    }
  }

  /// Build a collection item at [index] for the unified "All" tab list view.
  /// Index 0 = Wishlist, 1 = Loved, 2+ = individual playlists.
  Widget _buildAllTabListCollectionItem({
    required BuildContext context,
    required ColorScheme colorScheme,
    required int index,
    required LibraryCollectionsState collectionState,
    List<UnifiedLibraryItem> filteredUnifiedItems = const [],
  }) {
    if (index == 0) {
      return _buildCollectionListItem(
        context: context,
        colorScheme: colorScheme,
        icon: Icons.add_circle_outline,
        iconColor: Colors.white,
        iconBgColor: const Color(0xFF1DB954),
        title: context.l10n.collectionWishlist,
        subtitle:
            '${context.l10n.collectionFoldersTitle} • ${collectionState.wishlistCount} ${collectionState.wishlistCount == 1 ? 'track' : 'tracks'}',
        onTap: _openWishlistFolder,
      );
    } else if (index == 1) {
      return _buildCollectionListItem(
        context: context,
        colorScheme: colorScheme,
        icon: Icons.favorite,
        iconColor: Colors.white,
        iconBgColor: const Color(0xFF8C67AC),
        title: context.l10n.collectionLoved,
        subtitle:
            '${context.l10n.collectionFoldersTitle} • ${collectionState.lovedCount} ${collectionState.lovedCount == 1 ? 'track' : 'tracks'}',
        onTap: _openLovedFolder,
      );
    } else {
      final playlist = collectionState.playlists[index - 2];
      final isSelected = _selectedPlaylistIds.contains(playlist.id);
      return DragTarget<UnifiedLibraryItem>(
        onWillAcceptWithDetails: (_) => !_isPlaylistSelectionMode,
        onAcceptWithDetails: (details) {
          _onTrackDroppedOnPlaylist(
            context,
            details.data,
            playlist.id,
            playlist.name,
            allItems: filteredUnifiedItems,
          );
        },
        builder: (context, candidateData, rejectedData) {
          final isHovering = candidateData.isNotEmpty;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            decoration: isHovering
                ? BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: colorScheme.primary, width: 2),
                    color: colorScheme.primary.withValues(alpha: 0.1),
                  )
                : null,
            child: Row(
              children: [
                if (_isPlaylistSelectionMode)
                  Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: Container(
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
                              size: 18,
                              color: colorScheme.onPrimary,
                            )
                          : const SizedBox(width: 18, height: 18),
                    ),
                  ),
                Expanded(
                  child: _buildCollectionListItem(
                    context: context,
                    colorScheme: colorScheme,
                    coverWidget: _buildPlaylistCover(playlist, colorScheme, 56),
                    title: playlist.name,
                    subtitle:
                        '${playlist.tracks.length} ${playlist.tracks.length == 1 ? 'track' : 'tracks'}',
                    onTap: _isPlaylistSelectionMode
                        ? () => _togglePlaylistSelection(playlist.id)
                        : () => _openPlaylistById(playlist.id),
                    onLongPress: _isPlaylistSelectionMode
                        ? () => _togglePlaylistSelection(playlist.id)
                        : () => _enterPlaylistSelectionMode(playlist.id),
                  ),
                ),
              ],
            ),
          );
        },
      );
    }
  }

  Widget _buildFilterContent({
    required BuildContext context,
    required ColorScheme colorScheme,
    required String filterMode,
    required String historyViewMode,
    required bool hasQueueItems,
    required _FilterContentData filterData,
    required List<LocalLibraryItem> localLibraryItems,
    required LibraryCollectionsState collectionState,
  }) {
    final historyItems = filterData.historyItems;
    final showFilteringIndicator = filterData.showFilteringIndicator;
    final filteredGroupedAlbums = filterData.filteredGroupedAlbums;
    final filteredGroupedLocalAlbums = filterData.filteredGroupedLocalAlbums;
    final unifiedItems = filterData.unifiedItems;
    final filteredUnifiedItems = filterData.filteredUnifiedItems;
    final totalTrackCount = filterData.totalTrackCount;
    final totalAlbumCount = filterData.totalAlbumCount;

    return CustomScrollView(
      slivers: [
        if (totalTrackCount > 0 && filterMode == 'all')
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
                      onPressed: () => _showCreatePlaylistDialog(context),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(context.l10n.collectionCreatePlaylist),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ),

        // Collection folders as list items (Spotify-style) in "All" tab
        // are now rendered inline with tracks below (unified sliver)
        if ((filteredGroupedAlbums.isNotEmpty ||
                filteredGroupedLocalAlbums.isNotEmpty) &&
            filterMode == 'albums')
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  Text(
                    '$totalAlbumCount ${totalAlbumCount == 1 ? 'album' : 'albums'}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onLongPress: _activeFilterCount > 0 ? _resetFilters : null,
                    child: TextButton.icon(
                      onPressed: () => _showFilterSheet(context, unifiedItems),
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
                ],
              ),
            ),
          ),

        // Albums empty state with filter button
        if (filteredGroupedAlbums.isEmpty &&
            filteredGroupedLocalAlbums.isEmpty &&
            filterMode == 'albums' &&
            (historyItems.isNotEmpty || localLibraryItems.isNotEmpty))
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  const Spacer(),
                  GestureDetector(
                    onLongPress: _activeFilterCount > 0 ? _resetFilters : null,
                    child: TextButton.icon(
                      onPressed: () => _showFilterSheet(context, unifiedItems),
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
                ],
              ),
            ),
          ),

        if (historyItems.isNotEmpty && hasQueueItems)
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

        // Unified list/grid for 'all' filter: collection items + tracks combined
        if (filterMode == 'all') ...[
          if (historyViewMode == 'grid')
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final collectionCount =
                        2 + collectionState.playlists.length;
                    if (index < collectionCount) {
                      return _buildAllTabGridCollectionItem(
                        context: context,
                        colorScheme: colorScheme,
                        index: index,
                        collectionState: collectionState,
                        filteredUnifiedItems: filteredUnifiedItems,
                      );
                    }
                    final trackIndex = index - collectionCount;
                    if (trackIndex < filteredUnifiedItems.length) {
                      final item = filteredUnifiedItems[trackIndex];
                      return KeyedSubtree(
                        key: ValueKey(item.id),
                        child: LongPressDraggable<UnifiedLibraryItem>(
                          data: item,
                          feedback: _buildDragFeedback(
                            context,
                            item,
                            colorScheme,
                          ),
                          childWhenDragging: Opacity(
                            opacity: 0.4,
                            child: _buildUnifiedGridItem(
                              context,
                              item,
                              colorScheme,
                            ),
                          ),
                          child: _buildUnifiedGridItem(
                            context,
                            item,
                            colorScheme,
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                  childCount:
                      2 +
                      collectionState.playlists.length +
                      filteredUnifiedItems.length,
                ),
              ),
            )
          else
            SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final collectionCount = 2 + collectionState.playlists.length;
                  if (index < collectionCount) {
                    return _buildAllTabListCollectionItem(
                      context: context,
                      colorScheme: colorScheme,
                      index: index,
                      collectionState: collectionState,
                      filteredUnifiedItems: filteredUnifiedItems,
                    );
                  }
                  final trackIndex = index - collectionCount;
                  if (trackIndex < filteredUnifiedItems.length) {
                    final item = filteredUnifiedItems[trackIndex];
                    return KeyedSubtree(
                      key: ValueKey(item.id),
                      child: LongPressDraggable<UnifiedLibraryItem>(
                        data: item,
                        feedback: _buildDragFeedback(
                          context,
                          item,
                          colorScheme,
                        ),
                        childWhenDragging: Opacity(
                          opacity: 0.4,
                          child: _buildUnifiedLibraryItem(
                            context,
                            item,
                            colorScheme,
                          ),
                        ),
                        child: _buildUnifiedLibraryItem(
                          context,
                          item,
                          colorScheme,
                        ),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
                childCount:
                    2 +
                    collectionState.playlists.length +
                    filteredUnifiedItems.length,
              ),
            ),
        ],

        // Singles filter - show unified items (downloaded + local singles)
        if (filterMode == 'singles')
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
                      onPressed: () => _showCreatePlaylistDialog(context),
                      icon: const Icon(Icons.add, size: 20),
                      label: Text(context.l10n.collectionCreatePlaylist),
                      style: TextButton.styleFrom(
                        visualDensity: VisualDensity.compact,
                      ),
                    ),
                ],
              ),
            ),
          ),

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

        if (!hasQueueItems &&
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
    final embeddedCoverPath = _resolveDownloadedEmbeddedCoverPath(
      album.sampleFilePath,
    );
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
                  child: embeddedCoverPath != null
                      ? Image.file(
                          File(embeddedCoverPath),
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
                      : album.coverUrl != null
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

  bool _hasTextValue(String? value) => value != null && value.trim().isNotEmpty;

  List<UnifiedLibraryItem> _selectedItemsFromAll(
    List<UnifiedLibraryItem> allItems,
  ) {
    final itemsById = {for (final item in allItems) item.id: item};
    return _selectedIds
        .map((id) => itemsById[id])
        .whereType<UnifiedLibraryItem>()
        .toList(growable: false);
  }

  bool _isLocalOnlySelection(List<UnifiedLibraryItem> allItems) {
    final selectedItems = _selectedItemsFromAll(allItems);
    return selectedItems.isNotEmpty &&
        selectedItems.every((item) => item.localItem != null);
  }

  Future<void> _safeDeleteTempFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  Future<void> _cleanupTempFileAndParentDir(String path) async {
    await _safeDeleteTempFile(path);
    try {
      final parent = File(path).parent;
      if (await parent.exists()) {
        await parent.delete();
      }
    } catch (_) {}
  }

  Future<bool> _applyQueueFfmpegReEnrichResult(
    LocalLibraryItem item,
    Map<String, dynamic> result,
  ) async {
    final tempPath = result['temp_path'] as String?;
    final safUri = result['saf_uri'] as String?;
    final ffmpegTarget = _hasTextValue(tempPath) ? tempPath! : item.filePath;
    final downloadedCoverPath = result['cover_path'] as String?;
    String? effectiveCoverPath = downloadedCoverPath;
    String? extractedCoverPath;

    if (!_hasTextValue(effectiveCoverPath)) {
      try {
        final tempDir = await Directory.systemTemp.createTemp(
          'reenrich_cover_',
        );
        final coverOutput = '${tempDir.path}${Platform.pathSeparator}cover.jpg';
        final extracted = await PlatformBridge.extractCoverToFile(
          ffmpegTarget,
          coverOutput,
        );
        if (extracted['error'] == null) {
          effectiveCoverPath = coverOutput;
          extractedCoverPath = coverOutput;
        } else {
          try {
            await tempDir.delete(recursive: true);
          } catch (_) {}
        }
      } catch (_) {}
    }

    final metadata = (result['metadata'] as Map<String, dynamic>?)?.map(
      (k, v) => MapEntry(k, v.toString()),
    );

    final format = item.format?.toLowerCase();
    final lowerPath = item.filePath.toLowerCase();
    final isMp3 = format == 'mp3' || lowerPath.endsWith('.mp3');
    final isOpus =
        format == 'opus' ||
        format == 'ogg' ||
        lowerPath.endsWith('.opus') ||
        lowerPath.endsWith('.ogg');

    String? ffmpegResult;
    if (isMp3) {
      ffmpegResult = await FFmpegService.embedMetadataToMp3(
        mp3Path: ffmpegTarget,
        coverPath: effectiveCoverPath,
        metadata: metadata,
      );
    } else if (isOpus) {
      ffmpegResult = await FFmpegService.embedMetadataToOpus(
        opusPath: ffmpegTarget,
        coverPath: effectiveCoverPath,
        metadata: metadata,
      );
    }

    if (ffmpegResult != null &&
        _hasTextValue(tempPath) &&
        _hasTextValue(safUri)) {
      final ok = await PlatformBridge.writeTempToSaf(ffmpegResult, safUri!);
      if (!ok) {
        if (_hasTextValue(downloadedCoverPath)) {
          await _safeDeleteTempFile(downloadedCoverPath!);
        }
        if (_hasTextValue(extractedCoverPath)) {
          await _cleanupTempFileAndParentDir(extractedCoverPath!);
        }
        await _safeDeleteTempFile(tempPath!);
        return false;
      }
    }

    if (_hasTextValue(downloadedCoverPath)) {
      await _safeDeleteTempFile(downloadedCoverPath!);
    }
    if (_hasTextValue(extractedCoverPath)) {
      await _cleanupTempFileAndParentDir(extractedCoverPath!);
    }
    if (_hasTextValue(tempPath)) {
      await _safeDeleteTempFile(tempPath!);
    }

    return ffmpegResult != null;
  }

  Future<bool> _reEnrichQueueLocalTrack(LocalLibraryItem item) async {
    final durationMs = (item.duration ?? 0) * 1000;
    final request = <String, dynamic>{
      'file_path': item.filePath,
      'cover_url': '',
      'max_quality': true,
      'embed_lyrics': true,
      'spotify_id': '',
      'track_name': item.trackName,
      'artist_name': item.artistName,
      'album_name': item.albumName,
      'album_artist': item.albumArtist ?? item.artistName,
      'track_number': item.trackNumber ?? 0,
      'disc_number': item.discNumber ?? 0,
      'release_date': item.releaseDate ?? '',
      'isrc': item.isrc ?? '',
      'genre': item.genre ?? '',
      'label': '',
      'copyright': '',
      'duration_ms': durationMs,
      'search_online': true,
    };

    final result = await PlatformBridge.reEnrichFile(request);
    final method = result['method'] as String?;
    if (method == 'native') {
      return true;
    }
    if (method == 'ffmpeg') {
      return _applyQueueFfmpegReEnrichResult(item, result);
    }
    return false;
  }

  Future<void> _reEnrichSelectedLocalFromQueue(
    List<UnifiedLibraryItem> allItems,
  ) async {
    final selectedItems = _selectedItemsFromAll(allItems);
    final selectedLocalItems = selectedItems
        .map((item) => item.localItem)
        .whereType<LocalLibraryItem>()
        .toList(growable: false);

    if (selectedLocalItems.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.trackReEnrich),
        content: Text(
          '${context.l10n.trackReEnrichOnlineSubtitle}\n\n'
          '${context.l10n.downloadedAlbumSelectedCount(selectedLocalItems.length)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.trackReEnrich),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      return;
    }

    var successCount = 0;
    final total = selectedLocalItems.length;

    for (var i = 0; i < total; i++) {
      if (!mounted) break;
      final item = selectedLocalItems[i];

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${context.l10n.trackReEnrichProgress} (${i + 1}/$total)',
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      try {
        final ok = await _reEnrichQueueLocalTrack(item);
        if (ok) {
          successCount++;
        }
      } catch (_) {}
    }

    if (!mounted) {
      return;
    }

    final localLibraryPath = ref.read(settingsProvider).localLibraryPath.trim();
    try {
      if (localLibraryPath.isNotEmpty &&
          !ref.read(localLibraryProvider).isScanning) {
        await ref
            .read(localLibraryProvider.notifier)
            .startScan(localLibraryPath);
      } else {
        await ref.read(localLibraryProvider.notifier).reloadFromStorage();
      }
    } catch (_) {
      await ref.read(localLibraryProvider.notifier).reloadFromStorage();
    }

    _exitSelectionMode();

    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).clearSnackBars();
    final failedCount = total - successCount;
    final summary = failedCount <= 0
        ? '${context.l10n.trackReEnrichSuccess} ($successCount/$total)'
        : '${context.l10n.trackReEnrichSuccess} ($successCount/$total) • Failed: $failedCount';
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(summary)));
  }

  /// Share selected tracks via system share sheet
  Future<void> _shareSelected(List<UnifiedLibraryItem> allItems) async {
    final itemsById = {for (final item in allItems) item.id: item};
    final safUris = <String>[];
    final filesToShare = <XFile>[];

    for (final id in _selectedIds) {
      final item = itemsById[id];
      if (item == null) continue;
      final path = item.filePath;
      if (isContentUri(path)) {
        if (await fileExists(path)) safUris.add(path);
      } else if (await fileExists(path)) {
        filesToShare.add(XFile(path));
      }
    }

    if (safUris.isEmpty && filesToShare.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.selectionShareNoFiles)),
        );
      }
      return;
    }

    // Share SAF content URIs via native intent
    if (safUris.isNotEmpty) {
      try {
        if (safUris.length == 1) {
          await PlatformBridge.shareContentUri(safUris.first);
        } else {
          await PlatformBridge.shareMultipleContentUris(safUris);
        }
      } catch (_) {}
    }

    // Share regular files via SharePlus
    if (filesToShare.isNotEmpty) {
      await SharePlus.instance.share(ShareParams(files: filesToShare));
    }
  }

  /// Show batch convert bottom sheet for selected tracks
  void _showBatchConvertSheet(
    BuildContext context,
    List<UnifiedLibraryItem> allItems,
  ) {
    String selectedFormat = 'MP3';
    String selectedBitrate = '320k';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            final colorScheme = Theme.of(context).colorScheme;
            final formats = ['MP3', 'Opus'];
            final bitrates = ['128k', '192k', '256k', '320k'];

            return SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.selectionBatchConvertConfirmTitle,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      context.l10n.trackConvertTargetFormat,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: formats.map((format) {
                        final isSelected = format == selectedFormat;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: ChoiceChip(
                            label: Text(format),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setSheetState(() {
                                  selectedFormat = format;
                                  selectedBitrate = format == 'Opus'
                                      ? '128k'
                                      : '320k';
                                });
                              }
                            },
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.trackConvertBitrate,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: bitrates.map((br) {
                        final isSelected = br == selectedBitrate;
                        return ChoiceChip(
                          label: Text(br),
                          selected: isSelected,
                          onSelected: (selected) {
                            if (selected) {
                              setSheetState(() => selectedBitrate = br);
                            }
                          },
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _performBatchConversion(
                            allItems: allItems,
                            targetFormat: selectedFormat,
                            bitrate: selectedBitrate,
                          );
                        },
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          context.l10n.selectionConvertCount(
                            _selectedIds.length,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Perform batch conversion on selected tracks
  Future<void> _performBatchConversion({
    required List<UnifiedLibraryItem> allItems,
    required String targetFormat,
    required String bitrate,
  }) async {
    final itemsById = {for (final item in allItems) item.id: item};
    final selectedItems = <UnifiedLibraryItem>[];
    for (final id in _selectedIds) {
      final item = itemsById[id];
      if (item == null) continue;
      // Detect format: use safFileName for download history SAF items,
      // item.localItem?.format for local library items, file extension as fallback
      String nameToCheck;
      if (item.historyItem?.safFileName != null &&
          item.historyItem!.safFileName!.isNotEmpty) {
        nameToCheck = item.historyItem!.safFileName!.toLowerCase();
      } else if (item.localItem?.format != null &&
          item.localItem!.format!.isNotEmpty) {
        // Synthesize a fake extension to keep detection unified
        nameToCheck = '.${item.localItem!.format!.toLowerCase()}';
      } else {
        nameToCheck = item.filePath.toLowerCase();
      }
      final ext = nameToCheck.endsWith('.flac')
          ? 'FLAC'
          : nameToCheck.endsWith('.mp3')
          ? 'MP3'
          : (nameToCheck.endsWith('.opus') || nameToCheck.endsWith('.ogg'))
          ? 'Opus'
          : null;
      if (ext != null && ext != targetFormat) {
        selectedItems.add(item);
      }
    }

    if (selectedItems.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(context.l10n.selectionConvertNoConvertible)),
        );
      }
      return;
    }

    // Confirm
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(context.l10n.selectionBatchConvertConfirmTitle),
        content: Text(
          context.l10n.selectionBatchConvertConfirmMessage(
            selectedItems.length,
            targetFormat,
            bitrate,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(context.l10n.dialogCancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(context.l10n.trackConvertFormat),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    int successCount = 0;
    final total = selectedItems.length;
    final historyDb = HistoryDatabase.instance;
    final newQuality =
        '${targetFormat.toUpperCase()} ${bitrate.trim().toLowerCase()}';
    final settings = ref.read(settingsProvider);
    final shouldEmbedLyrics =
        settings.embedLyrics && settings.lyricsMode != 'external';

    for (int i = 0; i < total; i++) {
      if (!mounted) break;
      final item = selectedItems[i];

      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.selectionBatchConvertProgress(i + 1, total),
          ),
          duration: const Duration(seconds: 30),
        ),
      );

      try {
        // Read metadata from file
        final metadata = <String, String>{
          'TITLE': item.trackName,
          'ARTIST': item.artistName,
          'ALBUM': item.albumName,
        };
        try {
          final result = await PlatformBridge.readFileMetadata(item.filePath);
          if (result['error'] == null) {
            result.forEach((key, value) {
              if (key == 'error' || value == null) return;
              final v = value.toString().trim();
              if (v.isEmpty) return;
              metadata[key.toUpperCase()] = v;
            });
          }
        } catch (_) {}
        await ensureLyricsMetadataForConversion(
          metadata: metadata,
          sourcePath: item.filePath,
          shouldEmbedLyrics: shouldEmbedLyrics,
          trackName: item.trackName,
          artistName: item.artistName,
          spotifyId: item.historyItem?.spotifyId ?? '',
          durationMs:
              ((item.historyItem?.duration ?? item.localItem?.duration) ?? 0) *
              1000,
        );

        // Extract cover art
        String? coverPath;
        try {
          final tempDir = await getTemporaryDirectory();
          final coverOutput =
              '${tempDir.path}${Platform.pathSeparator}batch_cover_${DateTime.now().millisecondsSinceEpoch}.jpg';
          final coverResult = await PlatformBridge.extractCoverToFile(
            item.filePath,
            coverOutput,
          );
          if (coverResult['error'] == null) {
            coverPath = coverOutput;
          }
        } catch (_) {}

        // Handle SAF vs regular file
        String workingPath = item.filePath;
        final isSaf = isContentUri(item.filePath);
        String? safTempPath;

        if (isSaf) {
          safTempPath = await PlatformBridge.copyContentUriToTemp(
            item.filePath,
          );
          if (safTempPath == null) continue;
          workingPath = safTempPath;
        }

        // Convert
        final newPath = await FFmpegService.convertAudioFormat(
          inputPath: workingPath,
          targetFormat: targetFormat.toLowerCase(),
          bitrate: bitrate,
          metadata: metadata,
          coverPath: coverPath,
          deleteOriginal: !isSaf,
        );

        // Cleanup cover temp
        if (coverPath != null) {
          try {
            await File(coverPath).delete();
          } catch (_) {}
        }

        if (newPath == null) {
          if (safTempPath != null) {
            try {
              await File(safTempPath).delete();
            } catch (_) {}
          }
          continue;
        }

        // Handle SAF write-back
        if (isSaf && item.historyItem != null) {
          final hi = item.historyItem!;
          final treeUri = hi.downloadTreeUri;
          final relativeDir = hi.safRelativeDir ?? '';
          if (treeUri != null && treeUri.isNotEmpty) {
            final oldFileName = hi.safFileName ?? '';
            final dotIdx = oldFileName.lastIndexOf('.');
            final baseName = dotIdx > 0
                ? oldFileName.substring(0, dotIdx)
                : oldFileName;
            final newExt = targetFormat.toLowerCase() == 'opus'
                ? '.opus'
                : '.mp3';
            final newFileName = '$baseName$newExt';
            final mimeType = targetFormat.toLowerCase() == 'opus'
                ? 'audio/opus'
                : 'audio/mpeg';

            final safUri = await PlatformBridge.createSafFileFromPath(
              treeUri: treeUri,
              relativeDir: relativeDir,
              fileName: newFileName,
              mimeType: mimeType,
              srcPath: newPath,
            );

            if (safUri == null || safUri.isEmpty) {
              try {
                await File(newPath).delete();
              } catch (_) {}
              if (safTempPath != null) {
                try {
                  await File(safTempPath).delete();
                } catch (_) {}
              }
              continue;
            }

            // Delete old SAF file
            try {
              await PlatformBridge.safDelete(item.filePath);
            } catch (_) {}

            // Update history
            await historyDb.updateFilePath(
              hi.id,
              safUri,
              newSafFileName: newFileName,
              newQuality: newQuality,
              clearAudioSpecs: true,
            );
          }
          // Cleanup temp files
          try {
            await File(newPath).delete();
          } catch (_) {}
          if (safTempPath != null) {
            try {
              await File(safTempPath).delete();
            } catch (_) {}
          }
        } else if (isSaf && item.localItem != null) {
          // Local library SAF item: parse content URI to derive tree and dir
          final uri = Uri.parse(item.filePath);
          final pathSegments = uri.pathSegments;

          String? treeUri;
          String relativeDir = '';
          String oldFileName = '';

          final treeIdx = pathSegments.indexOf('tree');
          final docIdx = pathSegments.indexOf('document');
          if (treeIdx >= 0 && treeIdx + 1 < pathSegments.length) {
            final treeId = pathSegments[treeIdx + 1];
            treeUri =
                'content://${uri.authority}/tree/${Uri.encodeComponent(treeId)}';
          }
          if (docIdx >= 0 && docIdx + 1 < pathSegments.length) {
            final docPath = Uri.decodeFull(pathSegments[docIdx + 1]);
            final slashIdx = docPath.lastIndexOf('/');
            if (slashIdx >= 0) {
              oldFileName = docPath.substring(slashIdx + 1);
              final treeId = treeIdx >= 0 && treeIdx + 1 < pathSegments.length
                  ? Uri.decodeFull(pathSegments[treeIdx + 1])
                  : '';
              if (treeId.isNotEmpty && docPath.startsWith(treeId)) {
                final afterTree = docPath.substring(treeId.length);
                final trimmed = afterTree.startsWith('/')
                    ? afterTree.substring(1)
                    : afterTree;
                final lastSlash = trimmed.lastIndexOf('/');
                relativeDir = lastSlash >= 0
                    ? trimmed.substring(0, lastSlash)
                    : '';
              }
            } else {
              oldFileName = docPath;
            }
          }

          if (treeUri != null && oldFileName.isNotEmpty) {
            final dotIdx = oldFileName.lastIndexOf('.');
            final baseName = dotIdx > 0
                ? oldFileName.substring(0, dotIdx)
                : oldFileName;
            final newExt = targetFormat.toLowerCase() == 'opus'
                ? '.opus'
                : '.mp3';
            final newFileName = '$baseName$newExt';
            final mimeType = targetFormat.toLowerCase() == 'opus'
                ? 'audio/opus'
                : 'audio/mpeg';

            final safUri = await PlatformBridge.createSafFileFromPath(
              treeUri: treeUri,
              relativeDir: relativeDir,
              fileName: newFileName,
              mimeType: mimeType,
              srcPath: newPath,
            );

            if (safUri == null || safUri.isEmpty) {
              try {
                await File(newPath).delete();
              } catch (_) {}
              if (safTempPath != null) {
                try {
                  await File(safTempPath).delete();
                } catch (_) {}
              }
              continue;
            }

            try {
              await PlatformBridge.safDelete(item.filePath);
            } catch (_) {}
            await LibraryDatabase.instance.deleteByPath(item.filePath);
          }

          // Cleanup temp files
          try {
            await File(newPath).delete();
          } catch (_) {}
          if (safTempPath != null) {
            try {
              await File(safTempPath).delete();
            } catch (_) {}
          }
        } else if (item.historyItem != null) {
          // Regular file - update history path
          await historyDb.updateFilePath(
            item.historyItem!.id,
            newPath,
            newQuality: newQuality,
            clearAudioSpecs: true,
          );
        } else if (item.localItem != null) {
          // Regular local library file - delete old db entry, rescan picks up new file
          await LibraryDatabase.instance.deleteByPath(item.filePath);
        }

        successCount++;
      } catch (_) {
        // Continue to next item on error
      }
    }

    // Reload history and local library to reflect path changes in UI
    ref.read(downloadHistoryProvider.notifier).reloadFromStorage();
    ref.read(localLibraryProvider.notifier).reloadFromStorage();

    _exitSelectionMode();

    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            context.l10n.selectionBatchConvertSuccess(
              successCount,
              total,
              targetFormat,
            ),
          ),
        ),
      );
    }
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
    final localOnlySelection = _isLocalOnlySelection(unifiedItems);

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

              const SizedBox(height: 12),

              // Action buttons row: Share/Re-enrich, Convert, Delete
              Row(
                children: [
                  Expanded(
                    child: _SelectionActionButton(
                      icon: localOnlySelection
                          ? Icons.auto_fix_high_outlined
                          : Icons.share_outlined,
                      label: localOnlySelection
                          ? '${context.l10n.trackReEnrich} ($selectedCount)'
                          : context.l10n.selectionShareCount(selectedCount),
                      onPressed: selectedCount > 0
                          ? () => localOnlySelection
                                ? _reEnrichSelectedLocalFromQueue(unifiedItems)
                                : _shareSelected(unifiedItems)
                          : null,
                      colorScheme: colorScheme,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SelectionActionButton(
                      icon: Icons.swap_horiz,
                      label: context.l10n.selectionConvertCount(selectedCount),
                      onPressed: selectedCount > 0
                          ? () => _showBatchConvertSheet(context, unifiedItems)
                          : null,
                      colorScheme: colorScheme,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 8),

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
                            // When progress is 0 (unknown size, e.g. YouTube tunnel mode),
                            // show bytes downloaded instead of percentage
                            item.progress > 0
                                ? (item.speedMBps > 0
                                      ? '${(item.progress * 100).toStringAsFixed(0)}% • ${item.speedMBps.toStringAsFixed(1)} MB/s'
                                      : '${(item.progress * 100).toStringAsFixed(0)}%')
                                : (item.bytesReceived > 0
                                      ? '${(item.bytesReceived / (1024 * 1024)).toStringAsFixed(1)} MB • ${item.speedMBps.toStringAsFixed(1)} MB/s'
                                      : (item.speedMBps > 0
                                            ? 'Downloading • ${item.speedMBps.toStringAsFixed(1)} MB/s'
                                            : 'Starting...')),
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
    final coverSize = _queueCoverSize();
    final memCacheSize = (coverSize * 2).round();

    return item.track.coverUrl != null
        ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: CachedNetworkImage(
              imageUrl: item.track.coverUrl!,
              width: coverSize,
              height: coverSize,
              fit: BoxFit.cover,
              memCacheWidth: memCacheSize,
              memCacheHeight: memCacheSize,
              cacheManager: CoverCacheManager.instance,
            ),
          )
        : Container(
            width: coverSize,
            height: coverSize,
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
        return ValueListenableBuilder<bool>(
          valueListenable: _fileExistsListenable(item.filePath),
          builder: (context, fileExists, child) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (fileExists)
                  IconButton(
                    onPressed: () => _openFile(
                      item.filePath!,
                      title: item.track.name,
                      artist: item.track.artistName,
                      album: item.track.albumName,
                      coverUrl: item.track.coverUrl ?? '',
                    ),
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
          },
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
    if (isDownloaded) {
      final embeddedCoverPath = _resolveDownloadedEmbeddedCoverPath(
        item.filePath,
      );
      if (embeddedCoverPath != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(embeddedCoverPath),
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
    }

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
    if (isDownloaded) {
      final embeddedCoverPath = _resolveDownloadedEmbeddedCoverPath(
        item.filePath,
      );
      if (embeddedCoverPath != null) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.file(
            File(embeddedCoverPath),
            fit: BoxFit.cover,
            cacheWidth: 200,
            cacheHeight: 200,
            errorBuilder: (context, error, stackTrace) => Container(
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
    }

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
    final fileExistsListenable = _fileExistsListenable(item.filePath);
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
            : () => _openFile(
                item.filePath,
                title: item.trackName,
                artist: item.artistName,
                album: item.albumName,
                coverUrl: item.coverUrl ?? item.localCoverPath ?? '',
              ),
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
                        Flexible(
                          child: Text(
                            dateStr,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.7),
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
                ValueListenableBuilder<bool>(
                  valueListenable: fileExistsListenable,
                  builder: (context, fileExists, child) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (fileExists)
                          IconButton(
                            onPressed: () => _openFile(
                              item.filePath,
                              title: item.trackName,
                              artist: item.artistName,
                              album: item.albumName,
                              coverUrl:
                                  item.coverUrl ?? item.localCoverPath ?? '',
                            ),
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
                    );
                  },
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
    final fileExistsListenable = _fileExistsListenable(item.filePath);
    final isSelected = _selectedIds.contains(item.id);
    final isDownloaded = item.source == LibraryItemSource.downloaded;

    return GestureDetector(
      onTap: _isSelectionMode
          ? () => _toggleSelection(item.id)
          : isDownloaded
          ? () => _navigateToHistoryMetadataScreen(item.historyItem!)
          : item.localItem != null
          ? () => _navigateToLocalMetadataScreen(item.localItem!)
          : () => _openFile(
              item.filePath,
              title: item.trackName,
              artist: item.artistName,
              album: item.albumName,
              coverUrl: item.coverUrl ?? item.localCoverPath ?? '',
            ),
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
                  if (!_isSelectionMode)
                    Positioned(
                      right: 4,
                      bottom: 4,
                      child: ValueListenableBuilder<bool>(
                        valueListenable: fileExistsListenable,
                        builder: (context, fileExists, child) {
                          return fileExists
                              ? GestureDetector(
                                  onTap: () => _openFile(
                                    item.filePath,
                                    title: item.trackName,
                                    artist: item.artistName,
                                    album: item.albumName,
                                    coverUrl:
                                        item.coverUrl ??
                                        item.localCoverPath ??
                                        '',
                                  ),
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
                                )
                              : Container(
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
                                );
                        },
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

class _QueueItemSliverRow extends ConsumerWidget {
  final String itemId;
  final ColorScheme colorScheme;
  final Widget Function(BuildContext, DownloadItem, ColorScheme) itemBuilder;

  const _QueueItemSliverRow({
    super.key,
    required this.itemId,
    required this.colorScheme,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = ref.watch(
      downloadQueueLookupProvider.select((lookup) => lookup.byItemId[itemId]),
    );
    if (item == null) {
      return const SizedBox.shrink();
    }

    return RepaintBoundary(child: itemBuilder(context, item, colorScheme));
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

/// Reusable action button for selection mode bottom bar
class _SelectionActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onPressed;
  final ColorScheme colorScheme;

  const _SelectionActionButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    required this.colorScheme,
  });

  @override
  Widget build(BuildContext context) {
    final isDisabled = onPressed == null;
    return Material(
      color: isDisabled
          ? colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)
          : colorScheme.secondaryContainer,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 18,
                color: isDisabled
                    ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                    : colorScheme.onSecondaryContainer,
              ),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDisabled
                        ? colorScheme.onSurfaceVariant.withValues(alpha: 0.5)
                        : colorScheme.onSecondaryContainer,
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
