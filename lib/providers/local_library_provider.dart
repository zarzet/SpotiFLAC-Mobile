import 'dart:async';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac_android/providers/download_queue_provider.dart';
import 'package:spotiflac_android/services/history_database.dart';
import 'package:spotiflac_android/services/library_database.dart';
import 'package:spotiflac_android/services/notification_service.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('LocalLibrary');

const _lastScannedAtKey = 'local_library_last_scanned_at';
const _excludedDownloadedCountKey = 'local_library_excluded_downloaded_count';
final _prefs = SharedPreferences.getInstance();

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
  final int excludedDownloadedCount;
  final Set<String> _trackKeySet;
  final Map<String, LocalLibraryItem> _byIsrc;
  final Map<String, LocalLibraryItem> _byTrackKey;

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
    this.excludedDownloadedCount = 0,
    Set<String>? trackKeySet,
    Map<String, LocalLibraryItem>? byIsrc,
    Map<String, LocalLibraryItem>? byTrackKey,
  }) : _trackKeySet = trackKeySet ?? items.map((item) => item.matchKey).toSet(),
       _byIsrc =
           byIsrc ??
           Map.fromEntries(
             items
                 .where((item) => item.isrc != null && item.isrc!.isNotEmpty)
                 .map((item) => MapEntry(item.isrc!, item)),
           ),
       _byTrackKey =
           byTrackKey ??
           Map.fromEntries(items.map((item) => MapEntry(item.matchKey, item)));

  bool hasIsrc(String isrc) => _byIsrc.containsKey(isrc);

  bool hasTrack(String trackName, String artistName) {
    final key = '${trackName.toLowerCase()}|${artistName.toLowerCase()}';
    return _trackKeySet.contains(key);
  }

  LocalLibraryItem? getByIsrc(String isrc) => _byIsrc[isrc];

  LocalLibraryItem? findByTrackAndArtist(String trackName, String artistName) {
    final key = '${trackName.toLowerCase()}|${artistName.toLowerCase()}';
    return _byTrackKey[key];
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
    int? excludedDownloadedCount,
  }) {
    final nextItems = items ?? this.items;
    final keepDerivedIndex = identical(nextItems, this.items);

    return LocalLibraryState(
      items: nextItems,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      scanCurrentFile: scanCurrentFile ?? this.scanCurrentFile,
      scanTotalFiles: scanTotalFiles ?? this.scanTotalFiles,
      scannedFiles: scannedFiles ?? this.scannedFiles,
      scanErrorCount: scanErrorCount ?? this.scanErrorCount,
      scanWasCancelled: scanWasCancelled ?? this.scanWasCancelled,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
      excludedDownloadedCount:
          excludedDownloadedCount ?? this.excludedDownloadedCount,
      trackKeySet: keepDerivedIndex ? _trackKeySet : null,
      byIsrc: keepDerivedIndex ? _byIsrc : null,
      byTrackKey: keepDerivedIndex ? _byTrackKey : null,
    );
  }
}

class LocalLibraryNotifier extends Notifier<LocalLibraryState> {
  final LibraryDatabase _db = LibraryDatabase.instance;
  final HistoryDatabase _historyDb = HistoryDatabase.instance;
  final NotificationService _notificationService = NotificationService();
  static const _progressPollingInterval = Duration(milliseconds: 800);
  Timer? _progressTimer;
  Timer? _progressStreamBootstrapTimer;
  StreamSubscription<Map<String, dynamic>>? _progressStreamSub;
  bool _isLoaded = false;
  bool _scanCancelRequested = false;
  int _progressPollingErrorCount = 0;
  bool _isProgressPollingInFlight = false;
  bool _hasReceivedProgressStreamEvent = false;
  bool _usingProgressStream = false;
  static const _scanNotificationHeartbeat = Duration(seconds: 4);
  int _lastScanNotificationPercent = -1;
  int _lastScanNotificationTotalFiles = -1;
  DateTime _lastScanNotificationAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  LocalLibraryState build() {
    ref.onDispose(() {
      _progressTimer?.cancel();
      _progressStreamBootstrapTimer?.cancel();
      _progressStreamSub?.cancel();
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
      final dbItemsFuture = _db.getAll();
      final prefsFuture = _prefs;
      final jsonList = await dbItemsFuture;
      final items = jsonList
          .map((e) => LocalLibraryItem.fromJson(e))
          .toList(growable: false);

      DateTime? lastScannedAt;
      var excludedDownloadedCount = 0;
      try {
        final prefs = await prefsFuture;
        final lastScannedAtStr = prefs.getString(_lastScannedAtKey);
        if (lastScannedAtStr != null && lastScannedAtStr.isNotEmpty) {
          lastScannedAt = DateTime.tryParse(lastScannedAtStr);
        }
        excludedDownloadedCount =
            prefs.getInt(_excludedDownloadedCountKey) ?? 0;
      } catch (e) {
        _log.w('Failed to load lastScannedAt: $e');
      }

      state = state.copyWith(
        items: items,
        lastScannedAt: lastScannedAt,
        excludedDownloadedCount: excludedDownloadedCount,
      );
      _log.i(
        'Loaded ${items.length} items from library database, lastScannedAt: '
        '$lastScannedAt, excludedDownloadedCount: $excludedDownloadedCount',
      );
    } catch (e, stack) {
      _log.e('Failed to load library from database: $e', e, stack);
    }
  }

  Future<void> reloadFromStorage() async {
    _isLoaded = false;
    await _loadFromDatabase();
  }

  Set<String> _buildPathMatchKeys(String? filePath) {
    final raw = filePath?.trim() ?? '';
    if (raw.isEmpty) return const {};

    final cleaned = raw.startsWith('EXISTS:') ? raw.substring(7) : raw;
    final keys = <String>{cleaned};

    void addNormalized(String value) {
      final trimmed = value.trim();
      if (trimmed.isEmpty) return;
      keys.add(trimmed);
      keys.add(trimmed.toLowerCase());
      if (trimmed.contains('\\')) {
        final slash = trimmed.replaceAll('\\', '/');
        keys.add(slash);
        keys.add(slash.toLowerCase());
      }
      if (trimmed.contains('%')) {
        try {
          final decoded = Uri.decodeFull(trimmed);
          keys.add(decoded);
          keys.add(decoded.toLowerCase());
        } catch (_) {}
      }
    }

    addNormalized(cleaned);

    if (cleaned.startsWith('content://')) {
      try {
        final uri = Uri.parse(cleaned);
        addNormalized(uri.toString());
        addNormalized(uri.replace(query: null, fragment: null).toString());
      } catch (_) {}
    }

    return keys;
  }

  bool _isDownloadedPath(String? filePath, Set<String> downloadedPathKeys) {
    if (filePath == null || filePath.isEmpty || downloadedPathKeys.isEmpty) {
      return false;
    }
    final candidateKeys = _buildPathMatchKeys(filePath);
    for (final key in candidateKeys) {
      if (downloadedPathKeys.contains(key)) {
        return true;
      }
    }
    return false;
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
    _resetScanNotificationTracking();
    if (_shouldShowScanProgressNotification(
      progress: 0,
      totalFiles: 0,
      isComplete: false,
    )) {
      await _showScanProgressNotification(
        progress: 0,
        scannedFiles: 0,
        totalFiles: 0,
        currentFile: null,
      );
    }

    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final coverCacheDir = '${appSupportDir.path}/library_covers';
      await PlatformBridge.setLibraryCoverCacheDir(coverCacheDir);
      _log.i('Cover cache directory set to: $coverCacheDir');
    } catch (e) {
      _log.w('Failed to set cover cache directory: $e');
    }

    _startProgressPolling();

    try {
      final isSaf = folderPath.startsWith('content://');

      // Get all file paths from download history to exclude them.
      // Merge DB + in-memory state to avoid race when a fresh download has not
      // been flushed to SQLite yet.
      final downloadedPaths = await _historyDb.getAllFilePaths();
      final inMemoryHistoryPaths = ref
          .read(downloadHistoryProvider)
          .items
          .map((item) => item.filePath)
          .where((path) => path.isNotEmpty);
      final allHistoryPaths = <String>{
        ...downloadedPaths,
        ...inMemoryHistoryPaths,
      };
      final downloadedPathKeys = <String>{};
      for (final path in allHistoryPaths) {
        downloadedPathKeys.addAll(_buildPathMatchKeys(path));
      }
      _log.i(
        'Excluding ${allHistoryPaths.length} downloaded files from library scan '
        '(${downloadedPathKeys.length} path keys)',
      );

      if (forceFullScan) {
        // Full scan path - ignores existing data
        final results = isSaf
            ? await PlatformBridge.scanSafTree(folderPath)
            : await PlatformBridge.scanLibraryFolder(folderPath);
        if (_scanCancelRequested) {
          state = state.copyWith(isScanning: false, scanWasCancelled: true);
          await _showScanCancelledNotification();
          return;
        }

        final items = <LocalLibraryItem>[];
        int skippedDownloads = 0;
        for (final json in results) {
          final filePath = json['filePath'] as String?;
          // Skip files that are already in download history
          if (_isDownloadedPath(filePath, downloadedPathKeys)) {
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
          await prefs.setInt(_excludedDownloadedCountKey, skippedDownloads);
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
          excludedDownloadedCount: skippedDownloads,
        );

        _log.i(
          'Full scan complete: ${items.length} tracks found, '
          '$skippedDownloads already in downloads',
        );
        await _showScanCompleteNotification(
          totalTracks: items.length,
          excludedDownloadedCount: skippedDownloads,
          errorCount: state.scanErrorCount,
        );
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
          await _showScanCancelledNotification();
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
            if (_isDownloadedPath(filePath, downloadedPathKeys)) {
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
          await prefs.setInt(_excludedDownloadedCountKey, skippedDownloads);
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
          excludedDownloadedCount: skippedDownloads,
        );

        _log.i(
          'Incremental scan complete: ${items.length} total tracks '
          '(${scannedList.length} new/updated, $skippedCount unchanged, '
          '${deletedPaths.length} removed, $skippedDownloads already in downloads)',
        );
        await _showScanCompleteNotification(
          totalTracks: items.length,
          excludedDownloadedCount: skippedDownloads,
          errorCount: state.scanErrorCount,
        );
      }
    } catch (e, stack) {
      _log.e('Library scan failed: $e', e, stack);
      state = state.copyWith(isScanning: false, scanWasCancelled: false);
      await _showScanFailedNotification(e.toString());
    } finally {
      _stopProgressPolling();
    }
  }

  void _startProgressPolling() {
    _progressTimer?.cancel();
    _progressStreamBootstrapTimer?.cancel();
    _progressStreamBootstrapTimer = null;
    _progressStreamSub?.cancel();
    _progressStreamSub = null;
    _hasReceivedProgressStreamEvent = false;
    _usingProgressStream = false;

    if (Platform.isAndroid || Platform.isIOS) {
      _progressStreamSub = PlatformBridge.libraryScanProgressStream().listen(
        (progress) async {
          _hasReceivedProgressStreamEvent = true;
          _usingProgressStream = true;
          _progressStreamBootstrapTimer?.cancel();
          _progressStreamBootstrapTimer = null;
          if (_isProgressPollingInFlight) return;
          _isProgressPollingInFlight = true;
          try {
            await _handleLibraryScanProgress(progress);
            _progressPollingErrorCount = 0;
          } catch (e) {
            _progressPollingErrorCount++;
            if (_progressPollingErrorCount <= 3) {
              _log.w('Library scan progress stream processing failed: $e');
            }
          } finally {
            _isProgressPollingInFlight = false;
          }
        },
        onError: (Object error, StackTrace stackTrace) {
          if (_usingProgressStream) {
            _log.w(
              'Library scan progress stream failed, fallback to polling: $error',
            );
          }
          _progressStreamSub?.cancel();
          _progressStreamSub = null;
          _usingProgressStream = false;
          _progressStreamBootstrapTimer?.cancel();
          _progressStreamBootstrapTimer = null;
          _startProgressPollingTimer();
        },
        cancelOnError: false,
      );

      _progressStreamBootstrapTimer = Timer(const Duration(seconds: 3), () {
        if (_hasReceivedProgressStreamEvent) {
          return;
        }
        _log.w('Library scan progress stream timeout, fallback to polling');
        _progressStreamSub?.cancel();
        _progressStreamSub = null;
        _usingProgressStream = false;
        _startProgressPollingTimer();
      });
      return;
    }

    _startProgressPollingTimer();
  }

  void _startProgressPollingTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(_progressPollingInterval, (_) async {
      if (_isProgressPollingInFlight) return;
      _isProgressPollingInFlight = true;
      try {
        final progress = await PlatformBridge.getLibraryScanProgress();
        await _handleLibraryScanProgress(progress);
        _progressPollingErrorCount = 0;
      } catch (e) {
        _progressPollingErrorCount++;
        if (_progressPollingErrorCount <= 3) {
          _log.w('Library scan progress polling failed: $e');
        }
      } finally {
        _isProgressPollingInFlight = false;
      }
    });
  }

  Future<void> _handleLibraryScanProgress(Map<String, dynamic> progress) async {
    final nextProgress = (progress['progress_pct'] as num?)?.toDouble() ?? 0;
    final normalizedProgress = ((nextProgress * 10).round() / 10).clamp(
      0.0,
      100.0,
    );
    final currentFile = progress['current_file'] as String?;
    final totalFiles = (progress['total_files'] as num?)?.toInt() ?? 0;
    final scannedFiles = (progress['scanned_files'] as num?)?.toInt() ?? 0;
    final errorCount = (progress['error_count'] as num?)?.toInt() ?? 0;
    final isComplete = progress['is_complete'] == true;

    final shouldUpdateState =
        state.scanProgress != normalizedProgress ||
        state.scanCurrentFile != currentFile ||
        state.scanTotalFiles != totalFiles ||
        state.scannedFiles != scannedFiles ||
        state.scanErrorCount != errorCount;

    if (shouldUpdateState) {
      state = state.copyWith(
        scanProgress: normalizedProgress,
        scanCurrentFile: currentFile,
        scanTotalFiles: totalFiles,
        scannedFiles: scannedFiles,
        scanErrorCount: errorCount,
      );
    }

    if (_shouldShowScanProgressNotification(
      progress: normalizedProgress,
      totalFiles: totalFiles,
      isComplete: isComplete,
    )) {
      await _showScanProgressNotification(
        progress: normalizedProgress,
        scannedFiles: scannedFiles,
        totalFiles: totalFiles,
        currentFile: currentFile,
      );
    }

    if (isComplete) {
      _stopProgressPolling();
    }
  }

  void _stopProgressPolling() {
    _progressTimer?.cancel();
    _progressStreamBootstrapTimer?.cancel();
    _progressStreamSub?.cancel();
    _progressTimer = null;
    _progressStreamBootstrapTimer = null;
    _progressStreamSub = null;
    _progressPollingErrorCount = 0;
    _isProgressPollingInFlight = false;
    _hasReceivedProgressStreamEvent = false;
    _usingProgressStream = false;
    _resetScanNotificationTracking();
  }

  void _resetScanNotificationTracking() {
    _lastScanNotificationPercent = -1;
    _lastScanNotificationTotalFiles = -1;
    _lastScanNotificationAt = DateTime.fromMillisecondsSinceEpoch(0);
  }

  bool _shouldShowScanProgressNotification({
    required double progress,
    required int totalFiles,
    required bool isComplete,
  }) {
    final now = DateTime.now();
    final percent = progress.round().clamp(0, 100);
    final percentChanged = percent != _lastScanNotificationPercent;
    final totalFilesChanged = totalFiles != _lastScanNotificationTotalFiles;
    final heartbeatDue =
        now.difference(_lastScanNotificationAt) >= _scanNotificationHeartbeat;

    if (!percentChanged && !totalFilesChanged && !isComplete && !heartbeatDue) {
      return false;
    }

    _lastScanNotificationPercent = percent;
    _lastScanNotificationTotalFiles = totalFiles;
    _lastScanNotificationAt = now;
    return true;
  }

  Future<void> cancelScan() async {
    if (!state.isScanning) return;

    _log.i('Cancelling library scan');
    _scanCancelRequested = true;
    await PlatformBridge.cancelLibraryScan();
    state = state.copyWith(isScanning: false, scanWasCancelled: true);
    _stopProgressPolling();
    await _showScanCancelledNotification();
  }

  Future<void> _showScanProgressNotification({
    required double progress,
    required int scannedFiles,
    required int totalFiles,
    required String? currentFile,
  }) async {
    try {
      await _notificationService.showLibraryScanProgress(
        progress: progress,
        scannedFiles: scannedFiles,
        totalFiles: totalFiles,
        currentFile: _shortenFileForNotification(currentFile),
      );
    } catch (e) {
      _log.w('Failed to show scan progress notification: $e');
    }
  }

  Future<void> _showScanCompleteNotification({
    required int totalTracks,
    required int excludedDownloadedCount,
    required int errorCount,
  }) async {
    try {
      await _notificationService.showLibraryScanComplete(
        totalTracks: totalTracks,
        excludedDownloadedCount: excludedDownloadedCount,
        errorCount: errorCount,
      );
    } catch (e) {
      _log.w('Failed to show scan complete notification: $e');
    }
  }

  Future<void> _showScanFailedNotification(String message) async {
    try {
      await _notificationService.showLibraryScanFailed(message);
    } catch (e) {
      _log.w('Failed to show scan failure notification: $e');
    }
  }

  Future<void> _showScanCancelledNotification() async {
    try {
      await _notificationService.showLibraryScanCancelled();
    } catch (e) {
      _log.w('Failed to show scan cancelled notification: $e');
    }
  }

  String? _shortenFileForNotification(String? path) {
    final raw = path?.trim() ?? '';
    if (raw.isEmpty) return null;

    var decoded = raw;
    try {
      decoded = Uri.decodeFull(raw);
    } catch (_) {}

    final slashIdx = decoded.lastIndexOf('/');
    final backslashIdx = decoded.lastIndexOf('\\');
    final cut = slashIdx > backslashIdx ? slashIdx : backslashIdx;
    if (cut >= 0 && cut < decoded.length - 1) {
      return decoded.substring(cut + 1);
    }
    return decoded;
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
      await prefs.remove(_excludedDownloadedCountKey);
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

    final paths = legacyPaths
        .where((path) => !path.startsWith('content://'))
        .toList(growable: false);
    const chunkSize = 24;
    final backfilled = <String, int>{};

    for (var i = 0; i < paths.length; i += chunkSize) {
      if (_scanCancelRequested) {
        break;
      }
      final end = (i + chunkSize < paths.length) ? i + chunkSize : paths.length;
      final chunk = paths.sublist(i, end);
      final chunkEntries = await Future.wait<MapEntry<String, int>?>(
        chunk.map((path) async {
          try {
            final stat = await File(path).stat();
            if (stat.type == FileSystemEntityType.file) {
              return MapEntry(path, stat.modified.millisecondsSinceEpoch);
            }
          } catch (_) {}
          return null;
        }),
      );
      for (final entry in chunkEntries) {
        if (entry != null) {
          backfilled[entry.key] = entry.value;
        }
      }
    }
    return backfilled;
  }
}

final localLibraryProvider =
    NotifierProvider<LocalLibraryNotifier, LocalLibraryState>(
      LocalLibraryNotifier.new,
    );
