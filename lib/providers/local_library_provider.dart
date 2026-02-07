import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac_android/services/history_database.dart';
import 'package:spotiflac_android/services/library_database.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('LocalLibrary');

const _lastScannedAtKey = 'local_library_last_scanned_at';

class LocalLibraryState {
  final List<LocalLibraryItem> items;
  final bool isScanning;
  final double scanProgress;
  final String? scanCurrentFile;
  final int scanTotalFiles;
  final int scannedFiles;
  final int scanErrorCount;
  final bool scanWasCancelled;
  final DateTime? lastScannedAt;
  final Set<String> _isrcSet;
  final Set<String> _trackKeySet;
  final Map<String, LocalLibraryItem> _byIsrc;

  LocalLibraryState({
    this.items = const [],
    this.isScanning = false,
    this.scanProgress = 0,
    this.scanCurrentFile,
    this.scanTotalFiles = 0,
    this.scannedFiles = 0,
    this.scanErrorCount = 0,
    this.scanWasCancelled = false,
    this.lastScannedAt,
  }) : _isrcSet = items
           .where((item) => item.isrc != null && item.isrc!.isNotEmpty)
           .map((item) => item.isrc!)
           .toSet(),
       _trackKeySet = items.map((item) => item.matchKey).toSet(),
       _byIsrc = Map.fromEntries(
         items
             .where((item) => item.isrc != null && item.isrc!.isNotEmpty)
             .map((item) => MapEntry(item.isrc!, item)),
       );

  bool hasIsrc(String isrc) => _isrcSet.contains(isrc);

  bool hasTrack(String trackName, String artistName) {
    final key = '${trackName.toLowerCase()}|${artistName.toLowerCase()}';
    return _trackKeySet.contains(key);
  }

  LocalLibraryItem? getByIsrc(String isrc) => _byIsrc[isrc];

  LocalLibraryItem? findByTrackAndArtist(String trackName, String artistName) {
    final key = '${trackName.toLowerCase()}|${artistName.toLowerCase()}';
    return items.where((item) => item.matchKey == key).firstOrNull;
  }

  bool existsInLibrary({String? isrc, String? trackName, String? artistName}) {
    if (isrc != null && isrc.isNotEmpty && hasIsrc(isrc)) {
      return true;
    }
    if (trackName != null && artistName != null) {
      return hasTrack(trackName, artistName);
    }
    return false;
  }

  LocalLibraryState copyWith({
    List<LocalLibraryItem>? items,
    bool? isScanning,
    double? scanProgress,
    String? scanCurrentFile,
    int? scanTotalFiles,
    int? scannedFiles,
    int? scanErrorCount,
    bool? scanWasCancelled,
    DateTime? lastScannedAt,
  }) {
    return LocalLibraryState(
      items: items ?? this.items,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      scanCurrentFile: scanCurrentFile ?? this.scanCurrentFile,
      scanTotalFiles: scanTotalFiles ?? this.scanTotalFiles,
      scannedFiles: scannedFiles ?? this.scannedFiles,
      scanErrorCount: scanErrorCount ?? this.scanErrorCount,
      scanWasCancelled: scanWasCancelled ?? this.scanWasCancelled,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
    );
  }
}

class LocalLibraryNotifier extends Notifier<LocalLibraryState> {
  final LibraryDatabase _db = LibraryDatabase.instance;
  final HistoryDatabase _historyDb = HistoryDatabase.instance;
  static const _progressPollingInterval = Duration(milliseconds: 800);
  Timer? _progressTimer;
  bool _isLoaded = false;
  bool _scanCancelRequested = false;
  int _progressPollingErrorCount = 0;

  @override
  LocalLibraryState build() {
    ref.onDispose(() {
      _progressTimer?.cancel();
    });

    Future.microtask(() async {
      await _loadFromDatabase();
    });
    return LocalLibraryState();
  }

  Future<void> _loadFromDatabase() async {
    if (_isLoaded) return;
    _isLoaded = true;

    try {
      final jsonList = await _db.getAll();
      final items = jsonList.map((e) => LocalLibraryItem.fromJson(e)).toList();

      DateTime? lastScannedAt;
      try {
        final prefs = await SharedPreferences.getInstance();
        final lastScannedAtStr = prefs.getString(_lastScannedAtKey);
        if (lastScannedAtStr != null && lastScannedAtStr.isNotEmpty) {
          lastScannedAt = DateTime.tryParse(lastScannedAtStr);
        }
      } catch (e) {
        _log.w('Failed to load lastScannedAt: $e');
      }

      state = state.copyWith(items: items, lastScannedAt: lastScannedAt);
      _log.i(
        'Loaded ${items.length} items from library database, lastScannedAt: $lastScannedAt',
      );
    } catch (e, stack) {
      _log.e('Failed to load library from database: $e', e, stack);
    }
  }

  Future<void> reloadFromStorage() async {
    _isLoaded = false;
    await _loadFromDatabase();
  }

  Future<void> startScan(
    String folderPath, {
    bool forceFullScan = false,
  }) async {
    if (state.isScanning) {
      _log.w('Scan already in progress');
      return;
    }

    _scanCancelRequested = false;
    _log.i(
      'Starting library scan: $folderPath (incremental: ${!forceFullScan})',
    );
    state = state.copyWith(
      isScanning: true,
      scanProgress: 0,
      scanCurrentFile: null,
      scanTotalFiles: 0,
      scannedFiles: 0,
      scanErrorCount: 0,
      scanWasCancelled: false,
    );

    try {
      final cacheDir = await getApplicationCacheDirectory();
      final coverCacheDir = '${cacheDir.path}/library_covers';
      await PlatformBridge.setLibraryCoverCacheDir(coverCacheDir);
      _log.i('Cover cache directory set to: $coverCacheDir');
    } catch (e) {
      _log.w('Failed to set cover cache directory: $e');
    }

    _startProgressPolling();

    try {
      final isSaf = folderPath.startsWith('content://');

      // Get all file paths from download history to exclude them
      final downloadedPaths = await _historyDb.getAllFilePaths();
      _log.i(
        'Excluding ${downloadedPaths.length} downloaded files from library scan',
      );

      if (forceFullScan) {
        // Full scan path - ignores existing data
        final results = isSaf
            ? await PlatformBridge.scanSafTree(folderPath)
            : await PlatformBridge.scanLibraryFolder(folderPath);
        if (_scanCancelRequested) {
          state = state.copyWith(isScanning: false, scanWasCancelled: true);
          return;
        }

        final items = <LocalLibraryItem>[];
        int skippedDownloads = 0;
        for (final json in results) {
          final filePath = json['filePath'] as String?;
          // Skip files that are already in download history
          if (filePath != null && downloadedPaths.contains(filePath)) {
            skippedDownloads++;
            continue;
          }
          final item = LocalLibraryItem.fromJson(json);
          items.add(item);
        }

        if (skippedDownloads > 0) {
          _log.i('Skipped $skippedDownloads files already in download history');
        }

        await _db.upsertBatch(items.map((e) => e.toJson()).toList());

        final now = DateTime.now();
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_lastScannedAtKey, now.toIso8601String());
          _log.d('Saved lastScannedAt: $now');
        } catch (e) {
          _log.w('Failed to save lastScannedAt: $e');
        }

        state = state.copyWith(
          items: items,
          isScanning: false,
          scanProgress: 100,
          lastScannedAt: now,
          scanWasCancelled: false,
        );

        _log.i('Full scan complete: ${items.length} tracks found');
      } else {
        // Incremental scan path - only scans new/modified files
        final existingFiles = await _db.getFileModTimes();
        _log.i(
          'Incremental scan: ${existingFiles.length} existing files in database',
        );

        final backfilledModTimes = await _backfillLegacyFileModTimes(
          isSaf: isSaf,
          existingFiles: existingFiles,
        );
        if (backfilledModTimes.isNotEmpty) {
          await _db.updateFileModTimes(backfilledModTimes);
          existingFiles.addAll(backfilledModTimes);
          _log.i('Backfilled ${backfilledModTimes.length} legacy mod times');
        }

        // Use appropriate incremental scan method based on SAF or not
        final Map<String, dynamic> result;
        if (isSaf) {
          result = await PlatformBridge.scanSafTreeIncremental(
            folderPath,
            existingFiles,
          );
        } else {
          result = await PlatformBridge.scanLibraryFolderIncremental(
            folderPath,
            existingFiles,
          );
        }

        if (_scanCancelRequested) {
          state = state.copyWith(isScanning: false, scanWasCancelled: true);
          return;
        }

        // Parse incremental scan result
        // SAF returns 'files' and 'removedUris', non-SAF returns 'scanned' and 'deletedPaths'
        final scannedList =
            (result['files'] as List<dynamic>?) ??
            (result['scanned'] as List<dynamic>?) ??
            [];
        final deletedPaths =
            (result['removedUris'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            (result['deletedPaths'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [];
        final skippedCount = result['skippedCount'] as int? ?? 0;
        final totalFiles = result['totalFiles'] as int? ?? 0;

        _log.i(
          'Incremental result: ${scannedList.length} scanned, '
          '$skippedCount skipped, ${deletedPaths.length} deleted, $totalFiles total',
        );

        final currentByPath = <String, LocalLibraryItem>{
          for (final item in state.items) item.filePath: item,
        };

        // Upsert new/modified items (excluding downloaded files)
        final updatedItems = <LocalLibraryItem>[];
        int skippedDownloads = 0;
        if (scannedList.isNotEmpty) {
          for (final json in scannedList) {
            final map = json as Map<String, dynamic>;
            final filePath = map['filePath'] as String?;
            if (filePath != null && downloadedPaths.contains(filePath)) {
              skippedDownloads++;
              continue;
            }
            final item = LocalLibraryItem.fromJson(map);
            updatedItems.add(item);
            currentByPath[item.filePath] = item;
          }
          if (updatedItems.isNotEmpty) {
            await _db.upsertBatch(updatedItems.map((e) => e.toJson()).toList());
            _log.i('Upserted ${updatedItems.length} items');
          }
          if (skippedDownloads > 0) {
            _log.i(
              'Skipped $skippedDownloads files already in download history',
            );
          }
        }

        // Delete removed items
        if (deletedPaths.isNotEmpty) {
          final deleteCount = await _db.deleteByPaths(deletedPaths);
          for (final path in deletedPaths) {
            currentByPath.remove(path);
          }
          _log.i('Deleted $deleteCount items from database');
        }

        final items = currentByPath.values.toList(growable: false)
          ..sort(_compareLibraryItems);

        final now = DateTime.now();
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString(_lastScannedAtKey, now.toIso8601String());
          _log.d('Saved lastScannedAt: $now');
        } catch (e) {
          _log.w('Failed to save lastScannedAt: $e');
        }

        state = state.copyWith(
          items: items,
          isScanning: false,
          scanProgress: 100,
          lastScannedAt: now,
          scanWasCancelled: false,
        );

        _log.i(
          'Incremental scan complete: ${items.length} total tracks '
          '(${scannedList.length} new/updated, $skippedCount unchanged, ${deletedPaths.length} removed)',
        );
      }
    } catch (e, stack) {
      _log.e('Library scan failed: $e', e, stack);
      state = state.copyWith(isScanning: false, scanWasCancelled: false);
    } finally {
      _stopProgressPolling();
    }
  }

  void _startProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(_progressPollingInterval, (_) async {
      try {
        final progress = await PlatformBridge.getLibraryScanProgress();

        state = state.copyWith(
          scanProgress: (progress['progress_pct'] as num?)?.toDouble() ?? 0,
          scanCurrentFile: progress['current_file'] as String?,
          scanTotalFiles: progress['total_files'] as int? ?? 0,
          scannedFiles: progress['scanned_files'] as int? ?? 0,
          scanErrorCount: progress['error_count'] as int? ?? 0,
        );

        if (progress['is_complete'] == true) {
          _stopProgressPolling();
        }
        _progressPollingErrorCount = 0;
      } catch (e) {
        _progressPollingErrorCount++;
        if (_progressPollingErrorCount <= 3) {
          _log.w('Library scan progress polling failed: $e');
        }
      }
    });
  }

  void _stopProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _progressPollingErrorCount = 0;
  }

  Future<void> cancelScan() async {
    if (!state.isScanning) return;

    _log.i('Cancelling library scan');
    _scanCancelRequested = true;
    await PlatformBridge.cancelLibraryScan();
    state = state.copyWith(isScanning: false, scanWasCancelled: true);
    _stopProgressPolling();
  }

  Future<int> cleanupMissingFiles() async {
    final removed = await _db.cleanupMissingFiles();
    if (removed > 0) {
      await reloadFromStorage();
    }
    return removed;
  }

  Future<void> clearLibrary() async {
    await _db.clearAll();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastScannedAtKey);
    } catch (e) {
      _log.w('Failed to clear lastScannedAt: $e');
    }

    state = LocalLibraryState();
    _log.i('Library cleared');
  }

  Future<void> removeItem(String id) async {
    await _db.delete(id);
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  bool existsInLibrary({String? isrc, String? trackName, String? artistName}) {
    return state.existsInLibrary(
      isrc: isrc,
      trackName: trackName,
      artistName: artistName,
    );
  }

  LocalLibraryItem? getByIsrc(String isrc) {
    return state.getByIsrc(isrc);
  }

  LocalLibraryItem? findExisting({
    String? isrc,
    String? trackName,
    String? artistName,
  }) {
    if (isrc != null && isrc.isNotEmpty) {
      final byIsrc = state.getByIsrc(isrc);
      if (byIsrc != null) return byIsrc;
    }
    if (trackName != null && artistName != null) {
      return state.findByTrackAndArtist(trackName, artistName);
    }
    return null;
  }

  Future<List<LocalLibraryItem>> search(String query) async {
    if (query.isEmpty) return [];

    final results = await _db.search(query);
    return results.map((e) => LocalLibraryItem.fromJson(e)).toList();
  }

  Future<int> getCount() async {
    return await _db.getCount();
  }

  int _compareLibraryItems(LocalLibraryItem a, LocalLibraryItem b) {
    final artistA = (a.albumArtist ?? a.artistName).toLowerCase();
    final artistB = (b.albumArtist ?? b.artistName).toLowerCase();
    final artistCompare = artistA.compareTo(artistB);
    if (artistCompare != 0) return artistCompare;

    final albumCompare = a.albumName.toLowerCase().compareTo(
      b.albumName.toLowerCase(),
    );
    if (albumCompare != 0) return albumCompare;

    final discCompare = (a.discNumber ?? 0).compareTo(b.discNumber ?? 0);
    if (discCompare != 0) return discCompare;

    return (a.trackNumber ?? 0).compareTo(b.trackNumber ?? 0);
  }

  Future<Map<String, int>> _backfillLegacyFileModTimes({
    required bool isSaf,
    required Map<String, int> existingFiles,
  }) async {
    final legacyPaths = existingFiles.entries
        .where((entry) => entry.value <= 0)
        .map((entry) => entry.key)
        .toList();
    if (legacyPaths.isEmpty) {
      return const {};
    }

    if (isSaf) {
      final uris = legacyPaths
          .where((path) => path.startsWith('content://'))
          .toList();
      if (uris.isEmpty) {
        return const {};
      }
      const chunkSize = 500;
      final backfilled = <String, int>{};
      try {
        for (var i = 0; i < uris.length; i += chunkSize) {
          if (_scanCancelRequested) {
            break;
          }
          final end = (i + chunkSize < uris.length)
              ? i + chunkSize
              : uris.length;
          final chunk = uris.sublist(i, end);
          final chunkResult = await PlatformBridge.getSafFileModTimes(chunk);
          backfilled.addAll(chunkResult);
        }
        return backfilled;
      } catch (e) {
        _log.w('Failed to backfill SAF mod times: $e');
        return const {};
      }
    }

    final backfilled = <String, int>{};
    for (final path in legacyPaths) {
      if (_scanCancelRequested || path.startsWith('content://')) {
        continue;
      }
      try {
        final stat = await File(path).stat();
        if (stat.type == FileSystemEntityType.file) {
          backfilled[path] = stat.modified.millisecondsSinceEpoch;
        }
      } catch (_) {}
    }
    return backfilled;
  }
}

final localLibraryProvider =
    NotifierProvider<LocalLibraryNotifier, LocalLibraryState>(
      LocalLibraryNotifier.new,
    );
