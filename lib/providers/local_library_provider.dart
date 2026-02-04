import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac_android/services/library_database.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('LocalLibrary');

const _lastScannedAtKey = 'local_library_last_scanned_at';

/// State for local library
class LocalLibraryState {
  final List<LocalLibraryItem> items;
  final bool isScanning;
  final double scanProgress;
  final String? scanCurrentFile;
  final int scanTotalFiles;
  final int scanErrorCount;
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
    this.scanErrorCount = 0,
    this.lastScannedAt,
  })  : _isrcSet = items
            .where((item) => item.isrc != null && item.isrc!.isNotEmpty)
            .map((item) => item.isrc!)
            .toSet(),
        _trackKeySet = items.map((item) => item.matchKey).toSet(),
        _byIsrc = Map.fromEntries(
          items
              .where((item) => item.isrc != null && item.isrc!.isNotEmpty)
              .map((item) => MapEntry(item.isrc!, item)),
        );

  /// Check if ISRC exists in library
  bool hasIsrc(String isrc) => _isrcSet.contains(isrc);

  /// Check if track exists by name and artist
  bool hasTrack(String trackName, String artistName) {
    final key = '${trackName.toLowerCase()}|${artistName.toLowerCase()}';
    return _trackKeySet.contains(key);
  }

  /// Find library item by ISRC
  LocalLibraryItem? getByIsrc(String isrc) => _byIsrc[isrc];

  /// Find library item by track name and artist
  LocalLibraryItem? findByTrackAndArtist(String trackName, String artistName) {
    final key = '${trackName.toLowerCase()}|${artistName.toLowerCase()}';
    return items.where((item) => item.matchKey == key).firstOrNull;
  }

  /// Check if a track exists in library (by ISRC or name matching)
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
    int? scanErrorCount,
    DateTime? lastScannedAt,
  }) {
    return LocalLibraryState(
      items: items ?? this.items,
      isScanning: isScanning ?? this.isScanning,
      scanProgress: scanProgress ?? this.scanProgress,
      scanCurrentFile: scanCurrentFile ?? this.scanCurrentFile,
      scanTotalFiles: scanTotalFiles ?? this.scanTotalFiles,
      scanErrorCount: scanErrorCount ?? this.scanErrorCount,
      lastScannedAt: lastScannedAt ?? this.lastScannedAt,
    );
  }
}

/// Provider for local library state management
class LocalLibraryNotifier extends Notifier<LocalLibraryState> {
  final LibraryDatabase _db = LibraryDatabase.instance;
  Timer? _progressTimer;
  bool _isLoaded = false;

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
      final items = jsonList
          .map((e) => LocalLibraryItem.fromJson(e))
          .toList();
      
      // Load lastScannedAt from SharedPreferences
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
      _log.i('Loaded ${items.length} items from library database, lastScannedAt: $lastScannedAt');
    } catch (e, stack) {
      _log.e('Failed to load library from database: $e', e, stack);
    }
  }

  /// Reload library from database
  Future<void> reloadFromStorage() async {
    _isLoaded = false;
    await _loadFromDatabase();
  }

  /// Start scanning a folder for audio files
  Future<void> startScan(String folderPath) async {
    if (state.isScanning) {
      _log.w('Scan already in progress');
      return;
    }

    _log.i('Starting library scan: $folderPath');
    state = state.copyWith(
      isScanning: true,
      scanProgress: 0,
      scanCurrentFile: null,
      scanTotalFiles: 0,
      scanErrorCount: 0,
    );

    // Set cover cache directory before scanning
    try {
      final cacheDir = await getApplicationCacheDirectory();
      final coverCacheDir = '${cacheDir.path}/library_covers';
      await PlatformBridge.setLibraryCoverCacheDir(coverCacheDir);
      _log.i('Cover cache directory set to: $coverCacheDir');
    } catch (e) {
      _log.w('Failed to set cover cache directory: $e');
    }

    // Start progress polling
    _startProgressPolling();

    try {
      final results = await PlatformBridge.scanLibraryFolder(folderPath);
      
      // Convert results to LocalLibraryItem and save to database
      final items = <LocalLibraryItem>[];
      for (final json in results) {
        final item = LocalLibraryItem.fromJson(json);
        items.add(item);
      }

      // Batch insert into database
      await _db.upsertBatch(items.map((e) => e.toJson()).toList());

      // Save lastScannedAt to SharedPreferences
      final now = DateTime.now();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_lastScannedAtKey, now.toIso8601String());
        _log.d('Saved lastScannedAt: $now');
      } catch (e) {
        _log.w('Failed to save lastScannedAt: $e');
      }

      // Update state
      state = state.copyWith(
        items: items,
        isScanning: false,
        scanProgress: 100,
        lastScannedAt: now,
      );

      _log.i('Scan complete: ${items.length} tracks found');
    } catch (e, stack) {
      _log.e('Library scan failed: $e', e, stack);
      state = state.copyWith(isScanning: false);
    } finally {
      _stopProgressPolling();
    }
  }

  void _startProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (_) async {
      try {
        final progress = await PlatformBridge.getLibraryScanProgress();
        
        state = state.copyWith(
          scanProgress: (progress['progress_pct'] as num?)?.toDouble() ?? 0,
          scanCurrentFile: progress['current_file'] as String?,
          scanTotalFiles: progress['total_files'] as int? ?? 0,
          scanErrorCount: progress['error_count'] as int? ?? 0,
        );

        if (progress['is_complete'] == true) {
          _stopProgressPolling();
        }
      } catch (_) {}
    });
  }

  void _stopProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = null;
  }

  /// Cancel ongoing scan
  Future<void> cancelScan() async {
    if (!state.isScanning) return;
    
    _log.i('Cancelling library scan');
    await PlatformBridge.cancelLibraryScan();
    state = state.copyWith(isScanning: false);
    _stopProgressPolling();
  }

  /// Clean up missing files from library
  Future<int> cleanupMissingFiles() async {
    final removed = await _db.cleanupMissingFiles();
    if (removed > 0) {
      await reloadFromStorage();
    }
    return removed;
  }

  /// Clear all library data
  Future<void> clearLibrary() async {
    await _db.clearAll();
    
    // Clear lastScannedAt from SharedPreferences
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_lastScannedAtKey);
    } catch (e) {
      _log.w('Failed to clear lastScannedAt: $e');
    }
    
    state = LocalLibraryState();
    _log.i('Library cleared');
  }

  /// Remove a single item from library by ID
  Future<void> removeItem(String id) async {
    await _db.delete(id);
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
  }

  /// Check if a track exists in library
  bool existsInLibrary({String? isrc, String? trackName, String? artistName}) {
    return state.existsInLibrary(
      isrc: isrc,
      trackName: trackName,
      artistName: artistName,
    );
  }

  /// Get library item by ISRC
  LocalLibraryItem? getByIsrc(String isrc) {
    return state.getByIsrc(isrc);
  }

  /// Find library item for a track
  LocalLibraryItem? findExisting({String? isrc, String? trackName, String? artistName}) {
    if (isrc != null && isrc.isNotEmpty) {
      final byIsrc = state.getByIsrc(isrc);
      if (byIsrc != null) return byIsrc;
    }
    if (trackName != null && artistName != null) {
      return state.findByTrackAndArtist(trackName, artistName);
    }
    return null;
  }

  /// Search library
  Future<List<LocalLibraryItem>> search(String query) async {
    if (query.isEmpty) return [];
    
    final results = await _db.search(query);
    return results.map((e) => LocalLibraryItem.fromJson(e)).toList();
  }

  /// Get library count
  Future<int> getCount() async {
    return await _db.getCount();
  }
}

final localLibraryProvider =
    NotifierProvider<LocalLibraryNotifier, LocalLibraryState>(
      LocalLibraryNotifier.new,
    );
