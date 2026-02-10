import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/models/settings.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/services/download_request_payload.dart';
import 'package:spotiflac_android/services/ffmpeg_service.dart';
import 'package:spotiflac_android/services/notification_service.dart';
import 'package:spotiflac_android/services/history_database.dart';
import 'package:spotiflac_android/utils/logger.dart';
import 'package:spotiflac_android/utils/file_access.dart';

final _log = AppLogger('DownloadQueue');
final _historyLog = AppLogger('DownloadHistory');

String? _normalizeOptionalString(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.toLowerCase() == 'null') return null;
  return trimmed;
}

final _invalidFolderChars = RegExp(r'[<>:"/\\|?*]');
final _trailingDotsRegex = RegExp(r'\.+$');
final _yearRegex = RegExp(r'^(\d{4})');

class DownloadHistoryItem {
  final String id;
  final String trackName;
  final String artistName;
  final String albumName;
  final String? albumArtist;
  final String? coverUrl;
  final String filePath;
  final String? storageMode;
  final String? downloadTreeUri;
  final String? safRelativeDir;
  final String? safFileName;
  final bool safRepaired;
  final String service;
  final DateTime downloadedAt;
  final String? isrc;
  final String? spotifyId;
  final int? trackNumber;
  final int? discNumber;
  final int? duration;
  final String? releaseDate;
  final String? quality;
  final int? bitDepth;
  final int? sampleRate;
  final String? genre;
  final String? label;
  final String? copyright;

  const DownloadHistoryItem({
    required this.id,
    required this.trackName,
    required this.artistName,
    required this.albumName,
    this.albumArtist,
    this.coverUrl,
    required this.filePath,
    this.storageMode,
    this.downloadTreeUri,
    this.safRelativeDir,
    this.safFileName,
    this.safRepaired = false,
    required this.service,
    required this.downloadedAt,
    this.isrc,
    this.spotifyId,
    this.trackNumber,
    this.discNumber,
    this.duration,
    this.releaseDate,
    this.quality,
    this.bitDepth,
    this.sampleRate,
    this.genre,
    this.label,
    this.copyright,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'trackName': trackName,
    'artistName': artistName,
    'albumName': albumName,
    'albumArtist': albumArtist,
    'coverUrl': coverUrl,
    'filePath': filePath,
    'storageMode': storageMode,
    'downloadTreeUri': downloadTreeUri,
    'safRelativeDir': safRelativeDir,
    'safFileName': safFileName,
    'safRepaired': safRepaired,
    'service': service,
    'downloadedAt': downloadedAt.toIso8601String(),
    'isrc': isrc,
    'spotifyId': spotifyId,
    'trackNumber': trackNumber,
    'discNumber': discNumber,
    'duration': duration,
    'releaseDate': releaseDate,
    'quality': quality,
    'bitDepth': bitDepth,
    'sampleRate': sampleRate,
    'genre': genre,
    'label': label,
    'copyright': copyright,
  };

  factory DownloadHistoryItem.fromJson(Map<String, dynamic> json) =>
      DownloadHistoryItem(
        id: json['id'] as String,
        trackName: json['trackName'] as String,
        artistName: json['artistName'] as String,
        albumName: json['albumName'] as String,
        albumArtist: _normalizeOptionalString(json['albumArtist'] as String?),
        coverUrl: json['coverUrl'] as String?,
        filePath: json['filePath'] as String,
        storageMode: json['storageMode'] as String?,
        downloadTreeUri: json['downloadTreeUri'] as String?,
        safRelativeDir: json['safRelativeDir'] as String?,
        safFileName: json['safFileName'] as String?,
        safRepaired: json['safRepaired'] == true,
        service: json['service'] as String,
        downloadedAt: DateTime.parse(json['downloadedAt'] as String),
        isrc: json['isrc'] as String?,
        spotifyId: json['spotifyId'] as String?,
        trackNumber: json['trackNumber'] as int?,
        discNumber: json['discNumber'] as int?,
        duration: json['duration'] as int?,
        releaseDate: json['releaseDate'] as String?,
        quality: json['quality'] as String?,
        bitDepth: json['bitDepth'] as int?,
        sampleRate: json['sampleRate'] as int?,
        genre: json['genre'] as String?,
        label: json['label'] as String?,
        copyright: json['copyright'] as String?,
      );

  DownloadHistoryItem copyWith({
    String? trackName,
    String? artistName,
    String? albumName,
    String? albumArtist,
    String? coverUrl,
    String? filePath,
    String? storageMode,
    String? downloadTreeUri,
    String? safRelativeDir,
    String? safFileName,
    bool? safRepaired,
    String? isrc,
    String? spotifyId,
    int? trackNumber,
    int? discNumber,
    int? duration,
    String? releaseDate,
    String? quality,
    int? bitDepth,
    int? sampleRate,
    String? genre,
    String? label,
    String? copyright,
  }) {
    return DownloadHistoryItem(
      id: id,
      trackName: trackName ?? this.trackName,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      albumArtist: albumArtist ?? this.albumArtist,
      coverUrl: coverUrl ?? this.coverUrl,
      filePath: filePath ?? this.filePath,
      storageMode: storageMode ?? this.storageMode,
      downloadTreeUri: downloadTreeUri ?? this.downloadTreeUri,
      safRelativeDir: safRelativeDir ?? this.safRelativeDir,
      safFileName: safFileName ?? this.safFileName,
      safRepaired: safRepaired ?? this.safRepaired,
      service: service,
      downloadedAt: downloadedAt,
      isrc: isrc ?? this.isrc,
      spotifyId: spotifyId ?? this.spotifyId,
      trackNumber: trackNumber ?? this.trackNumber,
      discNumber: discNumber ?? this.discNumber,
      duration: duration ?? this.duration,
      releaseDate: releaseDate ?? this.releaseDate,
      quality: quality ?? this.quality,
      bitDepth: bitDepth ?? this.bitDepth,
      sampleRate: sampleRate ?? this.sampleRate,
      genre: genre ?? this.genre,
      label: label ?? this.label,
      copyright: copyright ?? this.copyright,
    );
  }
}

class DownloadHistoryState {
  final List<DownloadHistoryItem> items;
  final Set<String> _downloadedSpotifyIds;
  final Map<String, DownloadHistoryItem> _bySpotifyId;
  final Map<String, DownloadHistoryItem> _byIsrc;

  DownloadHistoryState({this.items = const []})
    : _downloadedSpotifyIds = items
          .where((item) => item.spotifyId != null && item.spotifyId!.isNotEmpty)
          .map((item) => item.spotifyId!)
          .toSet(),
      _bySpotifyId = Map.fromEntries(
        items
            .where(
              (item) => item.spotifyId != null && item.spotifyId!.isNotEmpty,
            )
            .map((item) => MapEntry(item.spotifyId!, item)),
      ),
      _byIsrc = Map.fromEntries(
        items
            .where((item) => item.isrc != null && item.isrc!.isNotEmpty)
            .map((item) => MapEntry(item.isrc!, item)),
      );

  bool isDownloaded(String spotifyId) =>
      _downloadedSpotifyIds.contains(spotifyId);

  DownloadHistoryItem? getBySpotifyId(String spotifyId) =>
      _bySpotifyId[spotifyId];

  DownloadHistoryItem? getByIsrc(String isrc) => _byIsrc[isrc];

  DownloadHistoryState copyWith({List<DownloadHistoryItem>? items}) {
    return DownloadHistoryState(items: items ?? this.items);
  }
}

class DownloadHistoryNotifier extends Notifier<DownloadHistoryState> {
  static const int _safRepairBatchSize = 20;
  static const int _safRepairMaxPerLaunch = 60;
  final HistoryDatabase _db = HistoryDatabase.instance;
  bool _isLoaded = false;
  bool _isSafRepairInProgress = false;

  @override
  DownloadHistoryState build() {
    _loadFromDatabaseSync();
    return DownloadHistoryState();
  }

  void _loadFromDatabaseSync() {
    if (_isLoaded) return;
    _isLoaded = true;
    Future.microtask(() async {
      await _loadFromDatabase();
    });
  }

  Future<void> _loadFromDatabase() async {
    try {
      final migrated = await _db.migrateFromSharedPreferences();
      if (migrated) {
        _historyLog.i('Migrated history from SharedPreferences to SQLite');
      }

      if (Platform.isIOS) {
        final pathsMigrated = await _db.migrateIosContainerPaths();
        if (pathsMigrated) {
          _historyLog.i('Migrated iOS container paths after app update');
        }
      }

      final jsonList = await _db.getAll();
      final items = jsonList
          .map((e) => DownloadHistoryItem.fromJson(e))
          .toList();

      state = state.copyWith(items: items);
      _historyLog.i('Loaded ${items.length} items from SQLite database');

      if (Platform.isAndroid) {
        Future.microtask(() async {
          await _repairMissingSafEntries(
            items,
            maxItems: _safRepairMaxPerLaunch,
          );
          await cleanupOrphanedDownloads();
        });
      } else {
        Future.microtask(() => cleanupOrphanedDownloads());
      }
    } catch (e, stack) {
      _historyLog.e('Failed to load history from database: $e', e, stack);
    }
  }

  String _fileNameFromUri(String uri) {
    try {
      final parsed = Uri.parse(uri);
      if (parsed.pathSegments.isNotEmpty) {
        return Uri.decodeComponent(parsed.pathSegments.last);
      }
    } catch (_) {}
    return '';
  }

  Future<void> _repairMissingSafEntries(
    List<DownloadHistoryItem> items, {
    required int maxItems,
  }) async {
    if (_isSafRepairInProgress || items.isEmpty) {
      return;
    }
    _isSafRepairInProgress = true;

    final candidateIndexes = <int>[];
    for (var i = 0; i < items.length; i++) {
      final item = items[i];
      if (item.storageMode != 'saf') continue;
      if (item.safRepaired) continue;
      if (item.downloadTreeUri == null || item.downloadTreeUri!.isEmpty) {
        continue;
      }
      if (item.filePath.isEmpty || !isContentUri(item.filePath)) {
        continue;
      }
      candidateIndexes.add(i);
      if (candidateIndexes.length >= maxItems) break;
    }

    if (candidateIndexes.isEmpty) {
      _isSafRepairInProgress = false;
      return;
    }

    final updatedItems = [...items];
    var changed = false;
    var repairedCount = 0;
    var verifiedCount = 0;

    try {
      for (var c = 0; c < candidateIndexes.length; c++) {
        final i = candidateIndexes[c];
        final item = items[i];

        final exists = await fileExists(item.filePath);
        if (exists) {
          final verified = item.copyWith(
            safRepaired: true,
            safFileName: item.safFileName ?? _fileNameFromUri(item.filePath),
          );
          updatedItems[i] = verified;
          changed = true;
          verifiedCount++;
          await _db.upsert(verified.toJson());
        } else {
          final fallbackName =
              item.safFileName ?? _fileNameFromUri(item.filePath);
          if (fallbackName.isEmpty) {
            _historyLog.w('Missing SAF filename for history item: ${item.id}');
            continue;
          }

          try {
            final resolved = await PlatformBridge.resolveSafFile(
              treeUri: item.downloadTreeUri!,
              relativeDir: item.safRelativeDir ?? '',
              fileName: fallbackName,
            );
            final newUri = resolved['uri'] as String? ?? '';
            if (newUri.isEmpty) continue;

            final newRelativeDir = resolved['relative_dir'] as String?;
            final updated = item.copyWith(
              filePath: newUri,
              safRelativeDir:
                  (newRelativeDir != null && newRelativeDir.isNotEmpty)
                  ? newRelativeDir
                  : item.safRelativeDir,
              safFileName: fallbackName,
              safRepaired: true,
            );

            updatedItems[i] = updated;
            changed = true;
            repairedCount++;
            await _db.upsert(updated.toJson());
          } catch (e) {
            _historyLog.w('Failed to repair SAF URI: $e');
          }
        }

        if ((c + 1) % _safRepairBatchSize == 0) {
          await Future.delayed(const Duration(milliseconds: 16));
        }
      }

      if (changed) {
        state = state.copyWith(items: updatedItems);
        _historyLog.i(
          'SAF repair pass: verified=$verifiedCount, repaired=$repairedCount, checked=${candidateIndexes.length}',
        );
      }
    } finally {
      _isSafRepairInProgress = false;
    }
  }

  Future<void> reloadFromStorage() async {
    await _loadFromDatabase();
  }

  void addToHistory(DownloadHistoryItem item) {
    DownloadHistoryItem? existing;
    if (item.spotifyId != null && item.spotifyId!.isNotEmpty) {
      existing = state.getBySpotifyId(item.spotifyId!);
    }
    if (existing == null && item.isrc != null && item.isrc!.isNotEmpty) {
      existing = state.getByIsrc(item.isrc!);
    }

    if (existing != null) {
      final updatedItems = state.items
          .where((i) => i.id != existing!.id)
          .toList();
      updatedItems.insert(0, item);
      state = state.copyWith(items: updatedItems);
      _historyLog.d('Updated existing history entry: ${item.trackName}');
    } else {
      state = state.copyWith(items: [item, ...state.items]);
      _historyLog.d('Added new history entry: ${item.trackName}');
    }

    _db.upsert(item.toJson()).catchError((e) {
      _historyLog.e('Failed to save to database: $e');
    });
  }

  void removeFromHistory(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
    _db.deleteById(id).catchError((e) {
      _historyLog.e('Failed to delete from database: $e');
    });
  }

  void removeBySpotifyId(String spotifyId) {
    state = state.copyWith(
      items: state.items.where((item) => item.spotifyId != spotifyId).toList(),
    );
    _db.deleteBySpotifyId(spotifyId).catchError((e) {
      _historyLog.e('Failed to delete from database: $e');
    });
    _historyLog.d('Removed item with spotifyId: $spotifyId');
  }

  DownloadHistoryItem? getBySpotifyId(String spotifyId) {
    return state.getBySpotifyId(spotifyId);
  }

  DownloadHistoryItem? getByIsrc(String isrc) {
    return state.getByIsrc(isrc);
  }

  Future<DownloadHistoryItem?> getBySpotifyIdAsync(String spotifyId) async {
    final inMemory = state.getBySpotifyId(spotifyId);
    if (inMemory != null) return inMemory;

    final json = await _db.getBySpotifyId(spotifyId);
    if (json == null) return null;
    return DownloadHistoryItem.fromJson(json);
  }

  Future<void> updateMetadataForItem({
    required String id,
    required String trackName,
    required String artistName,
    required String albumName,
    String? albumArtist,
    String? isrc,
    int? trackNumber,
    int? discNumber,
    String? releaseDate,
    String? genre,
    String? label,
    String? copyright,
  }) async {
    final index = state.items.indexWhere((item) => item.id == id);
    if (index < 0) return;

    final current = state.items[index];
    final updated = current.copyWith(
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      albumArtist: albumArtist,
      isrc: isrc,
      trackNumber: trackNumber,
      discNumber: discNumber,
      releaseDate: releaseDate,
      genre: genre,
      label: label,
      copyright: copyright,
    );

    final updatedItems = [...state.items];
    updatedItems[index] = updated;
    state = state.copyWith(items: updatedItems);
    await _db.upsert(updated.toJson());
  }

  /// Remove history entries where the file no longer exists on disk
  /// Returns the number of orphaned entries removed
  Future<int> cleanupOrphanedDownloads() async {
    _historyLog.i('Starting orphaned downloads cleanup...');

    final entries = await _db.getAllEntriesWithPaths();
    final orphanedIds = <String>[];

    for (final entry in entries) {
      final id = entry['id'] as String;
      final filePath = entry['file_path'] as String?;

      if (filePath == null || filePath.isEmpty) continue;

      bool exists = false;

      if (filePath.startsWith('content://')) {
        // SAF path - check via platform bridge
        try {
          exists = await PlatformBridge.safExists(filePath);
        } catch (e) {
          _historyLog.w('Error checking SAF file existence: $e');
          exists = false;
        }
      } else {
        // Regular file path
        exists = File(filePath).existsSync();
      }

      if (!exists) {
        orphanedIds.add(id);
        _historyLog.d('Found orphaned entry: $id ($filePath)');
      }
    }

    if (orphanedIds.isEmpty) {
      _historyLog.i('No orphaned entries found');
      return 0;
    }

    // Delete from database
    final deletedCount = await _db.deleteByIds(orphanedIds);

    // Update in-memory state
    final orphanedSet = orphanedIds.toSet();
    state = state.copyWith(
      items: state.items
          .where((item) => !orphanedSet.contains(item.id))
          .toList(),
    );

    _historyLog.i('Cleaned up $deletedCount orphaned entries');
    return deletedCount;
  }

  void clearHistory() {
    state = DownloadHistoryState();
    _db.clearAll().catchError((e) {
      _historyLog.e('Failed to clear database: $e');
    });
  }

  Future<int> getDatabaseCount() async {
    return await _db.getCount();
  }
}

final downloadHistoryProvider =
    NotifierProvider<DownloadHistoryNotifier, DownloadHistoryState>(
      DownloadHistoryNotifier.new,
    );

class DownloadQueueState {
  final List<DownloadItem> items;
  final DownloadItem? currentDownload;
  final bool isProcessing;
  final bool isPaused;
  final String outputDir;
  final String filenameFormat;
  final String audioQuality;
  final bool autoFallback;
  final int concurrentDownloads;

  const DownloadQueueState({
    this.items = const [],
    this.currentDownload,
    this.isProcessing = false,
    this.isPaused = false,
    this.outputDir = '',
    this.filenameFormat = '{artist} - {title}',
    this.audioQuality = 'LOSSLESS',
    this.autoFallback = true,
    this.concurrentDownloads = 1,
  });

  DownloadQueueState copyWith({
    List<DownloadItem>? items,
    DownloadItem? currentDownload,
    bool? isProcessing,
    bool? isPaused,
    String? outputDir,
    String? filenameFormat,
    String? audioQuality,
    bool? autoFallback,
    int? concurrentDownloads,
  }) {
    return DownloadQueueState(
      items: items ?? this.items,
      currentDownload: currentDownload ?? this.currentDownload,
      isProcessing: isProcessing ?? this.isProcessing,
      isPaused: isPaused ?? this.isPaused,
      outputDir: outputDir ?? this.outputDir,
      filenameFormat: filenameFormat ?? this.filenameFormat,
      audioQuality: audioQuality ?? this.audioQuality,
      autoFallback: autoFallback ?? this.autoFallback,
      concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
    );
  }

  int get queuedCount => items
      .where(
        (i) =>
            i.status == DownloadStatus.queued ||
            i.status == DownloadStatus.downloading,
      )
      .length;
  int get completedCount =>
      items.where((i) => i.status == DownloadStatus.completed).length;
  int get failedCount =>
      items.where((i) => i.status == DownloadStatus.failed).length;
  int get activeDownloadsCount =>
      items.where((i) => i.status == DownloadStatus.downloading).length;
}

class _ProgressUpdate {
  final DownloadStatus status;
  final double progress;
  final double? speedMBps;
  final int? bytesReceived;

  const _ProgressUpdate({
    required this.status,
    required this.progress,
    this.speedMBps,
    this.bytesReceived,
  });
}

class DownloadQueueNotifier extends Notifier<DownloadQueueState> {
  Timer? _progressTimer;
  int _downloadCount = 0;
  static const _cleanupInterval = 50;
  static const _queueStorageKey = 'download_queue';
  static const _progressPollingInterval = Duration(milliseconds: 800);
  static const _queueSchedulingInterval = Duration(milliseconds: 250);
  final NotificationService _notificationService = NotificationService();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  int _totalQueuedAtStart = 0;
  int _completedInSession = 0;
  int _failedInSession = 0;
  bool _isLoaded = false;
  final Set<String> _ensuredDirs = {};
  int _progressPollingErrorCount = 0;
  String? _lastServiceTrackName;
  String? _lastServiceArtistName;
  int _lastServicePercent = -1;
  int _lastServiceQueueCount = -1;
  DateTime _lastServiceUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  DownloadQueueState build() {
    ref.listen<AppSettings>(settingsProvider, (previous, next) {
      final previousConcurrent =
          previous?.concurrentDownloads ?? state.concurrentDownloads;
      updateSettings(next);
      if (previousConcurrent != next.concurrentDownloads) {
        _log.i(
          'Concurrent downloads updated: $previousConcurrent -> ${next.concurrentDownloads}',
        );
      }
    });

    ref.onDispose(() {
      _progressTimer?.cancel();
      _progressTimer = null;
    });

    Future.microtask(() async {
      updateSettings(ref.read(settingsProvider));
      await _initOutputDir();
      await _loadQueueFromStorage();
    });
    return const DownloadQueueState();
  }

  Future<void> _loadQueueFromStorage() async {
    if (_isLoaded) return;
    _isLoaded = true;

    try {
      final prefs = await _prefs;
      final jsonStr = prefs.getString(_queueStorageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        final items = jsonList
            .map((e) => DownloadItem.fromJson(e as Map<String, dynamic>))
            .toList();

        final restoredItems = items.map((item) {
          if (item.status == DownloadStatus.downloading) {
            return item.copyWith(status: DownloadStatus.queued, progress: 0);
          }
          return item;
        }).toList();

        final pendingItems = restoredItems
            .where((item) => item.status == DownloadStatus.queued)
            .toList();

        if (pendingItems.isNotEmpty) {
          state = state.copyWith(items: pendingItems);
          _log.i('Restored ${pendingItems.length} pending items from storage');

          Future.microtask(() => _processQueue());
        } else {
          _log.d('No pending items to restore');
          await prefs.remove(_queueStorageKey);
        }
      } else {
        _log.d('No queue found in storage');
      }
    } catch (e) {
      _log.e('Failed to load queue from storage: $e');
    }
  }

  Future<void> _saveQueueToStorage() async {
    try {
      final prefs = await _prefs;

      final pendingItems = state.items
          .where(
            (item) =>
                item.status == DownloadStatus.queued ||
                item.status == DownloadStatus.downloading,
          )
          .toList();

      if (pendingItems.isEmpty) {
        await prefs.remove(_queueStorageKey);
        _log.d('Cleared queue storage (no pending items)');
      } else {
        final jsonList = pendingItems.map((e) => e.toJson()).toList();
        await prefs.setString(_queueStorageKey, jsonEncode(jsonList));
        _log.d('Saved ${pendingItems.length} pending items to storage');
      }
    } catch (e) {
      _log.e('Failed to save queue to storage: $e');
    }
  }

  void _startMultiProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(_progressPollingInterval, (timer) async {
      try {
        final allProgress = await PlatformBridge.getAllDownloadProgress();
        final items = allProgress['items'] as Map<String, dynamic>? ?? {};
        final currentItems = state.items;
        final itemsById = <String, DownloadItem>{};
        final itemIndexById = <String, int>{};
        int queuedCount = 0;
        int downloadingCount = 0;
        DownloadItem? firstDownloading;
        for (int i = 0; i < currentItems.length; i++) {
          final item = currentItems[i];
          itemsById[item.id] = item;
          itemIndexById[item.id] = i;
          if (item.status == DownloadStatus.downloading) {
            downloadingCount++;
            firstDownloading ??= item;
          }
          if (item.status == DownloadStatus.queued ||
              item.status == DownloadStatus.downloading) {
            queuedCount++;
          }
        }
        final progressUpdates = <String, _ProgressUpdate>{};

        bool hasFinalizingItem = false;
        String? finalizingTrackName;
        String? finalizingArtistName;

        for (final entry in items.entries) {
          final itemId = entry.key;
          final localItem = itemsById[itemId];
          if (localItem == null) {
            continue;
          }
          if (localItem.status == DownloadStatus.skipped) {
            PlatformBridge.clearItemProgress(itemId).catchError((_) {});
            continue;
          }
          if (localItem.status == DownloadStatus.completed ||
              localItem.status == DownloadStatus.failed) {
            continue;
          }
          final itemProgress = entry.value as Map<String, dynamic>;
          final bytesReceived = itemProgress['bytes_received'] as int? ?? 0;
          final bytesTotal = itemProgress['bytes_total'] as int? ?? 0;
          final speedMBps =
              (itemProgress['speed_mbps'] as num?)?.toDouble() ?? 0.0;
          final isDownloading =
              itemProgress['is_downloading'] as bool? ?? false;
          final status = itemProgress['status'] as String? ?? 'downloading';

          if (status == 'finalizing' && bytesTotal > 0) {
            progressUpdates[itemId] = const _ProgressUpdate(
              status: DownloadStatus.finalizing,
              progress: 1.0,
            );
            hasFinalizingItem = true;
            finalizingTrackName = localItem.track.name;
            finalizingArtistName = localItem.track.artistName;
            continue;
          }

          final progressFromBackend =
              (itemProgress['progress'] as num?)?.toDouble() ?? 0.0;

          if (isDownloading) {
            double percentage = 0.0;
            if (bytesTotal > 0) {
              percentage = bytesReceived / bytesTotal;
            } else {
              percentage = progressFromBackend;
            }

            progressUpdates[itemId] = _ProgressUpdate(
              status: DownloadStatus.downloading,
              progress: percentage,
              speedMBps: speedMBps,
              bytesReceived: bytesReceived,
            );

            final mbReceived = bytesReceived / (1024 * 1024);
            final mbTotal = bytesTotal / (1024 * 1024);
            if (bytesTotal > 0) {
              _log.d(
                'Progress [$itemId]: ${(percentage * 100).toStringAsFixed(1)}% (${mbReceived.toStringAsFixed(2)}/${mbTotal.toStringAsFixed(2)} MB) @ ${speedMBps.toStringAsFixed(2)} MB/s',
              );
            } else {
              _log.d(
                'Progress [$itemId]: ${(percentage * 100).toStringAsFixed(1)}% (DASH segments/unknown size) @ ${speedMBps.toStringAsFixed(2)} MB/s',
              );
            }
          }
        }

        if (progressUpdates.isNotEmpty) {
          var updatedItems = currentItems;
          bool changed = false;

          for (final entry in progressUpdates.entries) {
            final index = itemIndexById[entry.key];
            if (index == null) continue;
            final current = updatedItems[index];
            if (current.status == DownloadStatus.skipped ||
                current.status == DownloadStatus.completed ||
                current.status == DownloadStatus.failed) {
              continue;
            }
            final update = entry.value;
            final next = current.copyWith(
              status: update.status,
              progress: update.progress,
              speedMBps: update.speedMBps ?? current.speedMBps,
              bytesReceived: update.bytesReceived ?? current.bytesReceived,
            );
            if (current.status != next.status ||
                current.progress != next.progress ||
                current.speedMBps != next.speedMBps ||
                current.bytesReceived != next.bytesReceived) {
              if (!changed) {
                updatedItems = List<DownloadItem>.from(updatedItems);
                changed = true;
              }
              updatedItems[index] = next;
            }
          }

          if (changed) {
            state = state.copyWith(items: updatedItems);
          }
        }

        if (hasFinalizingItem && finalizingTrackName != null) {
          _notificationService.showDownloadFinalizing(
            trackName: finalizingTrackName,
            artistName: finalizingArtistName ?? '',
          );
          return;
        }

        if (items.isNotEmpty) {
          final firstEntry = items.entries.first;
          final firstProgress = firstEntry.value as Map<String, dynamic>;
          final bytesReceived = firstProgress['bytes_received'] as int? ?? 0;
          final bytesTotal = firstProgress['bytes_total'] as int? ?? 0;

          if (downloadingCount > 0 && firstDownloading != null) {
            final trackName = downloadingCount == 1
                ? firstDownloading.track.name
                : '$downloadingCount downloads';
            final artistName = downloadingCount == 1
                ? firstDownloading.track.artistName
                : 'Downloading...';

            int notifProgress = bytesReceived;
            int notifTotal = bytesTotal;

            if (bytesTotal <= 0) {
              final progressPercent =
                  (firstProgress['progress'] as num?)?.toDouble() ?? 0.0;
              notifProgress = (progressPercent * 100).toInt();
              notifTotal = 100;
            }

            _notificationService.showDownloadProgress(
              trackName: trackName,
              artistName: artistName,
              progress: notifProgress,
              total: notifTotal > 0 ? notifTotal : 1,
            );

            if (Platform.isAndroid) {
              _maybeUpdateAndroidDownloadService(
                trackName: firstDownloading.track.name,
                artistName: firstDownloading.track.artistName,
                progress: notifProgress,
                total: notifTotal > 0 ? notifTotal : 1,
                queueCount: queuedCount,
              );
            }
          }
        }
        _progressPollingErrorCount = 0;
      } catch (e) {
        _progressPollingErrorCount++;
        if (_progressPollingErrorCount <= 3) {
          _log.w('Progress polling failed: $e');
        }
      }
    });
  }

  void _maybeUpdateAndroidDownloadService({
    required String trackName,
    required String artistName,
    required int progress,
    required int total,
    required int queueCount,
  }) {
    final now = DateTime.now();
    final safeTotal = total > 0 ? total : 1;
    final progressPercent = ((progress * 100) / safeTotal)
        .round()
        .clamp(0, 100)
        .toInt();

    final didContentChange =
        trackName != _lastServiceTrackName ||
        artistName != _lastServiceArtistName ||
        queueCount != _lastServiceQueueCount ||
        progressPercent != _lastServicePercent;
    final allowHeartbeat =
        now.difference(_lastServiceUpdateAt) >= const Duration(seconds: 5);

    if (!didContentChange && !allowHeartbeat) {
      return;
    }

    _lastServiceTrackName = trackName;
    _lastServiceArtistName = artistName;
    _lastServicePercent = progressPercent;
    _lastServiceQueueCount = queueCount;
    _lastServiceUpdateAt = now;

    PlatformBridge.updateDownloadServiceProgress(
      trackName: trackName,
      artistName: artistName,
      progress: progress,
      total: safeTotal,
      queueCount: queueCount,
    ).catchError((_) {});
  }

  void _stopProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = null;
    _progressPollingErrorCount = 0;
    _lastServiceTrackName = null;
    _lastServiceArtistName = null;
    _lastServicePercent = -1;
    _lastServiceQueueCount = -1;
    _lastServiceUpdateAt = DateTime.fromMillisecondsSinceEpoch(0);
  }

  Future<void> _initOutputDir() async {
    if (state.outputDir.isEmpty) {
      try {
        if (Platform.isIOS) {
          final dir = await getApplicationDocumentsDirectory();
          final musicDir = Directory('${dir.path}/SpotiFLAC');
          if (!await musicDir.exists()) {
            await musicDir.create(recursive: true);
          }
          state = state.copyWith(outputDir: musicDir.path);
        } else {
          final dir = await getExternalStorageDirectory();
          if (dir != null) {
            final musicDir = Directory(
              '${dir.parent.parent.parent.parent.path}/Music/SpotiFLAC',
            );
            if (!await musicDir.exists()) {
              await musicDir.create(recursive: true);
            }
            state = state.copyWith(outputDir: musicDir.path);
          } else {
            final docDir = await getApplicationDocumentsDirectory();
            final musicDir = Directory('${docDir.path}/SpotiFLAC');
            if (!await musicDir.exists()) {
              await musicDir.create(recursive: true);
            }
            state = state.copyWith(outputDir: musicDir.path);
          }
        }
      } catch (e) {
        final dir = await getApplicationDocumentsDirectory();
        final musicDir = Directory('${dir.path}/SpotiFLAC');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
        state = state.copyWith(outputDir: musicDir.path);
      }
    }
  }

  Future<void> _ensureDirExists(String path, {String? label}) async {
    if (_ensuredDirs.contains(path)) return;
    final dir = Directory(path);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
      if (label != null) {
        _log.d('Created $label: $path');
      } else {
        _log.d('Created folder: $path');
      }
    }
    _ensuredDirs.add(path);
  }

  void setOutputDir(String dir) {
    state = state.copyWith(outputDir: dir);
  }

  Future<String> _buildOutputDir(
    Track track,
    String folderOrganization, {
    bool separateSingles = false,
    String albumFolderStructure = 'artist_album',
    bool useAlbumArtistForFolders = true,
    bool usePrimaryArtistOnly = false,
  }) async {
    String baseDir = state.outputDir;
    var folderArtist = useAlbumArtistForFolders
        ? _normalizeOptionalString(track.albumArtist) ?? track.artistName
        : track.artistName;
    if (usePrimaryArtistOnly) {
      folderArtist = _extractPrimaryArtist(folderArtist);
    }

    if (separateSingles) {
      final isSingle = track.isSingle;
      final artistName = _sanitizeFolderName(folderArtist);

      if (albumFolderStructure == 'artist_album_singles') {
        if (isSingle) {
          final singlesPath =
              '$baseDir${Platform.pathSeparator}$artistName${Platform.pathSeparator}Singles';
          await _ensureDirExists(singlesPath, label: 'Artist Singles folder');
          return singlesPath;
        } else {
          final albumName = _sanitizeFolderName(track.albumName);
          final albumPath =
              '$baseDir${Platform.pathSeparator}$artistName${Platform.pathSeparator}$albumName';
          await _ensureDirExists(albumPath, label: 'Artist Album folder');
          return albumPath;
        }
      }

      if (isSingle) {
        final singlesPath = '$baseDir${Platform.pathSeparator}Singles';
        await _ensureDirExists(singlesPath, label: 'Singles folder');
        return singlesPath;
      } else {
        final albumName = _sanitizeFolderName(track.albumName);
        final year = _extractYear(track.releaseDate);
        String albumPath;

        switch (albumFolderStructure) {
          case 'album_only':
            albumPath =
                '$baseDir${Platform.pathSeparator}Albums${Platform.pathSeparator}$albumName';
            break;
          case 'artist_year_album':
            final yearAlbum = year != null ? '[$year] $albumName' : albumName;
            albumPath =
                '$baseDir${Platform.pathSeparator}Albums${Platform.pathSeparator}$artistName${Platform.pathSeparator}$yearAlbum';
            break;
          case 'year_album':
            final yearAlbum = year != null ? '[$year] $albumName' : albumName;
            albumPath =
                '$baseDir${Platform.pathSeparator}Albums${Platform.pathSeparator}$yearAlbum';
            break;
          default:
            albumPath =
                '$baseDir${Platform.pathSeparator}Albums${Platform.pathSeparator}$artistName${Platform.pathSeparator}$albumName';
        }

        await _ensureDirExists(albumPath, label: 'Album folder');
        return albumPath;
      }
    }

    if (folderOrganization == 'none') {
      return baseDir;
    }

    String subPath = '';
    switch (folderOrganization) {
      case 'artist':
        final artistName = _sanitizeFolderName(folderArtist);
        subPath = artistName;
        break;
      case 'album':
        final albumName = _sanitizeFolderName(track.albumName);
        subPath = albumName;
        break;
      case 'artist_album':
        final artistName = _sanitizeFolderName(folderArtist);
        final albumName = _sanitizeFolderName(track.albumName);
        subPath = '$artistName${Platform.pathSeparator}$albumName';
        break;
    }

    if (subPath.isNotEmpty) {
      final fullPath = '$baseDir${Platform.pathSeparator}$subPath';
      await _ensureDirExists(fullPath);
      return fullPath;
    }

    return baseDir;
  }

  String _sanitizeFolderName(String name) {
    return name
        .replaceAll(_invalidFolderChars, '_')
        .replaceAll(_trailingDotsRegex, '')
        .trim();
  }

  static final _featuredArtistPattern = RegExp(
    r'\s*[,;&]\s*|\s+(?:feat\.?|ft\.?|featuring|with|x)\s+',
    caseSensitive: false,
  );

  String _extractPrimaryArtist(String artist) {
    final match = _featuredArtistPattern.firstMatch(artist);
    if (match != null && match.start > 0) {
      return artist.substring(0, match.start).trim();
    }
    return artist;
  }

  bool _isSafMode(AppSettings settings) {
    return Platform.isAndroid &&
        settings.storageMode == 'saf' &&
        settings.downloadTreeUri.isNotEmpty;
  }

  bool _isSafWriteFailure(Map<String, dynamic> result) {
    final error = (result['error'] ?? result['message'] ?? '')
        .toString()
        .toLowerCase();
    if (error.isEmpty) return false;
    return error.contains('saf') ||
        error.contains('content uri') ||
        error.contains('permission denied') ||
        error.contains('documentfile');
  }

  Future<String> _buildRelativeOutputDir(
    Track track,
    String folderOrganization, {
    bool separateSingles = false,
    String albumFolderStructure = 'artist_album',
    bool useAlbumArtistForFolders = true,
    bool usePrimaryArtistOnly = false,
  }) async {
    var folderArtist = useAlbumArtistForFolders
        ? _normalizeOptionalString(track.albumArtist) ?? track.artistName
        : track.artistName;
    if (usePrimaryArtistOnly) {
      folderArtist = _extractPrimaryArtist(folderArtist);
    }

    if (separateSingles) {
      final isSingle = track.isSingle;
      final artistName = _sanitizeFolderName(folderArtist);

      if (albumFolderStructure == 'artist_album_singles') {
        if (isSingle) {
          return '$artistName/Singles';
        }
        final albumName = _sanitizeFolderName(track.albumName);
        return '$artistName/$albumName';
      }

      if (isSingle) {
        return 'Singles';
      }

      final albumName = _sanitizeFolderName(track.albumName);
      final year = _extractYear(track.releaseDate);
      switch (albumFolderStructure) {
        case 'album_only':
          return 'Albums/$albumName';
        case 'artist_year_album':
          final yearAlbum = year != null ? '[$year] $albumName' : albumName;
          return 'Albums/$artistName/$yearAlbum';
        case 'year_album':
          final yearAlbum = year != null ? '[$year] $albumName' : albumName;
          return 'Albums/$yearAlbum';
        default:
          return 'Albums/$artistName/$albumName';
      }
    }

    if (folderOrganization == 'none') {
      return '';
    }

    switch (folderOrganization) {
      case 'artist':
        return _sanitizeFolderName(folderArtist);
      case 'album':
        return _sanitizeFolderName(track.albumName);
      case 'artist_album':
        final artistName = _sanitizeFolderName(folderArtist);
        final albumName = _sanitizeFolderName(track.albumName);
        return '$artistName/$albumName';
      default:
        return '';
    }
  }

  String _determineOutputExt(String quality, String service) {
    // YouTube provider - lossy only (Opus or MP3)
    if (service.toLowerCase() == 'youtube') {
      if (quality.toLowerCase().contains('mp3')) {
        return '.mp3';
      }
      return '.opus';
    }
    // Amazon stream is delivered as MP4/M4A container (may contain FLAC audio),
    // so SAF should keep .m4a before decrypt/convert pipeline.
    if (service.toLowerCase() == 'amazon') {
      return '.m4a';
    }
    if (service.toLowerCase() == 'tidal' && quality == 'HIGH') {
      return '.m4a';
    }
    return '.flac';
  }

  String _mimeTypeForExt(String ext) {
    switch (ext.toLowerCase()) {
      case '.m4a':
        return 'audio/mp4';
      case '.mp3':
        return 'audio/mpeg';
      case '.opus':
        return 'audio/ogg';
      case '.flac':
        return 'audio/flac';
      case '.lrc':
        return 'application/octet-stream';
      default:
        return 'application/octet-stream';
    }
  }

  Future<String?> _getSafMimeType(String uri) async {
    try {
      final stat = await PlatformBridge.safStat(uri);
      return stat['mime_type'] as String?;
    } catch (_) {
      return null;
    }
  }

  String? _extractYear(String? releaseDate) {
    if (releaseDate == null || releaseDate.isEmpty) return null;
    final match = _yearRegex.firstMatch(releaseDate);
    return match?.group(1);
  }

  static final _isrcRegex = RegExp(r'^[A-Z]{2}[A-Z0-9]{3}\d{2}\d{5}$');

  bool _isValidISRC(String value) {
    return _isrcRegex.hasMatch(value.toUpperCase());
  }

  void updateSettings(AppSettings settings) {
    final concurrentDownloads = settings.concurrentDownloads.clamp(1, 5);
    state = state.copyWith(
      outputDir: settings.downloadDirectory.isNotEmpty
          ? settings.downloadDirectory
          : state.outputDir,
      filenameFormat: settings.filenameFormat,
      audioQuality: settings.audioQuality,
      autoFallback: settings.autoFallback,
      concurrentDownloads: concurrentDownloads,
    );
  }

  String addToQueue(Track track, String service, {String? qualityOverride}) {
    final settings = ref.read(settingsProvider);
    updateSettings(settings);

    final id =
        '${track.isrc ?? track.id}-${DateTime.now().millisecondsSinceEpoch}';
    final item = DownloadItem(
      id: id,
      track: track,
      service: service,
      createdAt: DateTime.now(),
      qualityOverride: qualityOverride,
    );

    state = state.copyWith(items: [...state.items, item]);
    _saveQueueToStorage();

    if (!state.isProcessing) {
      Future.microtask(() => _processQueue());
    }

    return id;
  }

  void addMultipleToQueue(
    List<Track> tracks,
    String service, {
    String? qualityOverride,
  }) {
    final settings = ref.read(settingsProvider);
    updateSettings(settings);

    final newItems = tracks.map((track) {
      final id =
          '${track.isrc ?? track.id}-${DateTime.now().millisecondsSinceEpoch}';
      return DownloadItem(
        id: id,
        track: track,
        service: service,
        createdAt: DateTime.now(),
        qualityOverride: qualityOverride,
      );
    }).toList();

    state = state.copyWith(items: [...state.items, ...newItems]);
    _saveQueueToStorage();

    if (!state.isProcessing) {
      Future.microtask(() => _processQueue());
    }
  }

  void updateItemStatus(
    String id,
    DownloadStatus status, {
    double? progress,
    double? speedMBps,
    String? filePath,
    String? error,
    DownloadErrorType? errorType,
  }) {
    final items = state.items;
    final index = items.indexWhere((item) => item.id == id);
    if (index == -1) return;

    final current = items[index];
    final next = current.copyWith(
      status: status,
      progress: progress ?? current.progress,
      speedMBps: speedMBps ?? current.speedMBps,
      filePath: filePath,
      error: error,
      errorType: errorType,
    );

    if (current.status == next.status &&
        current.progress == next.progress &&
        current.speedMBps == next.speedMBps &&
        current.filePath == next.filePath &&
        current.error == next.error &&
        current.errorType == next.errorType) {
      return;
    }

    final updatedItems = List<DownloadItem>.from(items);
    updatedItems[index] = next;
    state = state.copyWith(items: updatedItems);

    if (status == DownloadStatus.completed ||
        status == DownloadStatus.failed ||
        status == DownloadStatus.skipped) {
      _saveQueueToStorage();
    }
  }

  void updateProgress(String id, double progress, {double? speedMBps}) {
    final items = state.items;
    final index = items.indexWhere((i) => i.id == id);
    if (index == -1) return;
    final item = items[index];
    if (item.status == DownloadStatus.skipped ||
        item.status == DownloadStatus.completed ||
        item.status == DownloadStatus.failed) {
      return;
    }
    updateItemStatus(
      id,
      DownloadStatus.downloading,
      progress: progress,
      speedMBps: speedMBps,
    );
  }

  void cancelItem(String id) {
    updateItemStatus(id, DownloadStatus.skipped);
    PlatformBridge.cancelDownload(id).catchError((_) {});
    PlatformBridge.clearItemProgress(id).catchError((_) {});
  }

  void clearCompleted() {
    final items = state.items
        .where(
          (item) =>
              item.status != DownloadStatus.completed &&
              item.status != DownloadStatus.failed &&
              item.status != DownloadStatus.skipped,
        )
        .toList();

    state = state.copyWith(items: items);
    _saveQueueToStorage();
  }

  void clearAll() {
    state = state.copyWith(items: [], isPaused: false);
    _saveQueueToStorage();
  }

  void pauseQueue() {
    if (state.isProcessing && !state.isPaused) {
      state = state.copyWith(isPaused: true);
      _notificationService.cancelDownloadNotification();
      _log.i('Queue paused');
    }
  }

  void resumeQueue() {
    if (state.isPaused) {
      state = state.copyWith(isPaused: false);
      _log.i('Queue resumed');
      if (state.queuedCount > 0 && !state.isProcessing) {
        Future.microtask(() => _processQueue());
      }
    }
  }

  void togglePause() {
    if (state.isPaused) {
      resumeQueue();
    } else {
      pauseQueue();
    }
  }

  void retryItem(String id) {
    final item = state.items.where((i) => i.id == id).firstOrNull;
    if (item == null) {
      _log.w('retryItem: Item not found: $id');
      return;
    }

    if (item.status != DownloadStatus.failed &&
        item.status != DownloadStatus.skipped) {
      _log.w('retryItem: Item status is ${item.status}, not retrying');
      return;
    }

    _log.i('Retrying item: ${item.track.name} (id: $id)');

    final items = state.items.map((i) {
      if (i.id == id) {
        return i.copyWith(
          status: DownloadStatus.queued,
          progress: 0,
          error: null,
        );
      }
      return i;
    }).toList();
    state = state.copyWith(items: items);
    _saveQueueToStorage();

    if (!state.isProcessing) {
      _log.d('Starting queue processing for retry');
      Future.microtask(() => _processQueue());
    } else {
      _log.d('Queue already processing, item will be picked up');
    }
  }

  void removeItem(String id) {
    final items = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: items);
    _saveQueueToStorage();
  }

  Future<String?> exportFailedDownloads() async {
    final failedItems = state.items
        .where((item) => item.status == DownloadStatus.failed)
        .toList();

    if (failedItems.isEmpty) {
      _log.d('No failed downloads to export');
      return null;
    }

    try {
      String baseDir = state.outputDir;
      if (baseDir.isEmpty) {
        final dir = await getApplicationDocumentsDirectory();
        baseDir = dir.path;
      }

      final failedDownloadsDir = '$baseDir/failed_downloads';
      final failedDir = Directory(failedDownloadsDir);
      if (!await failedDir.exists()) {
        await failedDir.create(recursive: true);
      }

      // Use date-only format for daily grouping (YYYY-MM-DD)
      final now = DateTime.now();
      final dateStr =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final fileName = 'failed_downloads_$dateStr.txt';
      final filePath = '$failedDownloadsDir/$fileName';

      final file = File(filePath);
      final bool fileExists = await file.exists();

      final buffer = StringBuffer();

      if (!fileExists) {
        buffer.writeln('# SpotiFLAC Failed Downloads');
        buffer.writeln('# Date: $dateStr');
        buffer.writeln('#');
        buffer.writeln('# Format: [Time] Track - Artist | URL | Error');
        buffer.writeln('');
      }

      final timeStr =
          '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

      for (final item in failedItems) {
        final track = item.track;
        final spotifyUrl = track.id.startsWith('deezer:')
            ? 'https://www.deezer.com/track/${track.id.substring(7)}'
            : 'https://open.spotify.com/track/${track.id}';
        final error = item.error ?? 'Unknown error';
        buffer.writeln(
          '[$timeStr] ${track.name} - ${track.artistName} | $spotifyUrl | $error',
        );
      }

      if (fileExists) {
        await file.writeAsString(buffer.toString(), mode: FileMode.append);
        _log.i('Appended ${failedItems.length} failed downloads to: $filePath');
      } else {
        await file.writeAsString(buffer.toString());
        _log.i('Created new failed downloads file: $filePath');
      }

      return filePath;
    } catch (e) {
      _log.e('Failed to export failed downloads: $e');
      return null;
    }
  }

  void clearFailedDownloads() {
    final items = state.items
        .where((item) => item.status != DownloadStatus.failed)
        .toList();
    state = state.copyWith(items: items);
    _saveQueueToStorage();
    _log.d('Cleared failed downloads from queue');
  }

  Future<void> _runPostProcessingHooks(String filePath, Track track) async {
    try {
      final settings = ref.read(settingsProvider);
      final extensionState = ref.read(extensionProvider);

      if (!settings.useExtensionProviders) return;

      final hasPostProcessing = extensionState.extensions.any(
        (e) => e.enabled && e.hasPostProcessing,
      );
      if (!hasPostProcessing) return;

      _log.d('Running post-processing hooks on: $filePath');

      final metadata = <String, dynamic>{
        'title': track.name,
        'artist': track.artistName,
        'album': track.albumName,
        'album_artist':
            _normalizeOptionalString(track.albumArtist) ?? track.artistName,
        'track_number': track.trackNumber ?? 1,
        'disc_number': track.discNumber ?? 1,
        'isrc': track.isrc ?? '',
        'release_date': track.releaseDate ?? '',
        'duration_ms': track.duration * 1000,
        'cover_url': track.coverUrl ?? '',
      };

      final result = await PlatformBridge.runPostProcessingV2(
        filePath,
        metadata: metadata,
      );

      if (result['success'] == true) {
        final hooksRun = result['hooks_run'] as int? ?? 0;
        final newPath = result['file_path'] as String?;
        _log.i('Post-processing completed: $hooksRun hook(s) executed');

        if (newPath != null && newPath != filePath) {
          _log.d('File path changed by post-processing: $newPath');
        }
      } else {
        final error = result['error'] as String? ?? 'Unknown error';
        _log.w('Post-processing failed: $error');
      }
    } catch (e) {
      _log.w('Post-processing error: $e');
    }
  }

  String _upgradeToMaxQualityCover(String coverUrl) {
    const spotifySize300 = 'ab67616d00001e02';
    const spotifySize640 = 'ab67616d0000b273';
    const spotifySizeMax = 'ab67616d000082c1';

    var result = coverUrl;
    if (result.contains(spotifySize300)) {
      result = result.replaceFirst(spotifySize300, spotifySize640);
    }

    if (result.contains(spotifySize640)) {
      result = result.replaceFirst(spotifySize640, spotifySizeMax);
    }

    return result;
  }

  int? _parsePositiveInt(dynamic value) {
    if (value is int && value > 0) return value;
    if (value is String) {
      final parsed = int.tryParse(value);
      if (parsed != null && parsed > 0) return parsed;
    }
    return null;
  }

  Track _buildTrackForMetadataEmbedding(
    Track baseTrack,
    Map<String, dynamic> backendResult,
    String? normalizedAlbumArtist,
  ) {
    final backendTrackNum = _parsePositiveInt(backendResult['track_number']);
    final backendDiscNum = _parsePositiveInt(backendResult['disc_number']);
    final backendYear = _normalizeOptionalString(
      backendResult['release_date'] as String?,
    );
    final backendAlbum = _normalizeOptionalString(
      backendResult['album'] as String?,
    );

    if (backendTrackNum == null &&
        backendDiscNum == null &&
        backendYear == null &&
        backendAlbum == null) {
      return baseTrack;
    }

    return Track(
      id: baseTrack.id,
      name: baseTrack.name,
      artistName: baseTrack.artistName,
      albumName: backendAlbum ?? baseTrack.albumName,
      albumArtist: normalizedAlbumArtist,
      coverUrl: baseTrack.coverUrl,
      duration: baseTrack.duration,
      isrc: baseTrack.isrc,
      trackNumber: backendTrackNum ?? baseTrack.trackNumber,
      discNumber: backendDiscNum ?? baseTrack.discNumber,
      releaseDate: backendYear ?? baseTrack.releaseDate,
      deezerId: baseTrack.deezerId,
      availability: baseTrack.availability,
      albumType: baseTrack.albumType,
      source: baseTrack.source,
    );
  }

  Future<void> _embedMetadataAndCover(
    String flacPath,
    Track track, {
    String? genre,
    String? label,
    String? copyright,
  }) async {
    final settings = ref.read(settingsProvider);

    String? coverPath;
    var coverUrl = track.coverUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      try {
        if (settings.maxQualityCover) {
          coverUrl = _upgradeToMaxQualityCover(coverUrl);
          _log.d('Cover URL upgraded to max quality: $coverUrl');
        }

        final tempDir = await getTemporaryDirectory();
        final uniqueId =
            '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
        coverPath = '${tempDir.path}/cover_$uniqueId.jpg';

        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(coverUrl));
        final response = await request.close();
        if (response.statusCode == 200) {
          final file = File(coverPath);
          final sink = file.openWrite();
          await response.pipe(sink);
          await sink.close();
          _log.d('Cover downloaded to temp: $coverPath');
        } else {
          _log.w('Failed to download cover: HTTP ${response.statusCode}');
          coverPath = null;
        }
        httpClient.close();
      } catch (e) {
        _log.e('Failed to download cover: $e');
        coverPath = null;
      }
    }

    try {
      final metadata = <String, String>{
        'TITLE': track.name,
        'ARTIST': track.artistName,
        'ALBUM': track.albumName,
      };

      final albumArtist =
          _normalizeOptionalString(track.albumArtist) ?? track.artistName;
      metadata['ALBUMARTIST'] = albumArtist;

      if (track.trackNumber != null) {
        metadata['TRACKNUMBER'] = track.trackNumber.toString();
        metadata['TRACK'] = track.trackNumber.toString();
      }

      if (track.discNumber != null) {
        metadata['DISCNUMBER'] = track.discNumber.toString();
        metadata['DISC'] = track.discNumber.toString();
      }

      if (track.releaseDate != null) {
        metadata['DATE'] = track.releaseDate!;
        metadata['YEAR'] = track.releaseDate!.split('-').first;
      }

      if (track.isrc != null) {
        metadata['ISRC'] = track.isrc!;
      }

      if (genre != null && genre.isNotEmpty) {
        metadata['GENRE'] = genre;
        _log.d('Adding GENRE: $genre');
      }
      if (label != null && label.isNotEmpty) {
        metadata['ORGANIZATION'] = label;
        _log.d('Adding ORGANIZATION (label): $label');
      }
      if (copyright != null && copyright.isNotEmpty) {
        metadata['COPYRIGHT'] = copyright;
        _log.d('Adding COPYRIGHT: $copyright');
      }

      _log.d('Metadata map content: $metadata');

      try {
        final durationMs = track.duration * 1000;

        final lrcContent = await PlatformBridge.getLyricsLRC(
          track.id,
          track.name,
          track.artistName,
          filePath: '',
          durationMs: durationMs,
        );

        if (lrcContent.isNotEmpty && lrcContent != '[instrumental:true]') {
          metadata['LYRICS'] = lrcContent;
          metadata['UNSYNCEDLYRICS'] = lrcContent;
          _log.d('Lyrics fetched for embedding (${lrcContent.length} chars)');
        } else if (lrcContent == '[instrumental:true]') {
          _log.d('Track is instrumental, skipping lyrics embedding');
        }
      } catch (e) {
        _log.w('Failed to fetch lyrics for embedding: $e');
      }

      _log.d('Generating tags for FLAC: $metadata');

      final result = await FFmpegService.embedMetadata(
        flacPath: flacPath,
        coverPath: coverPath != null && await File(coverPath).exists()
            ? coverPath
            : null,
        metadata: metadata,
      );

      if (result != null) {
        _log.d('Metadata and cover embedded via FFmpeg');
      } else {
        _log.w('FFmpeg metadata/cover embed failed');
      }

      if (coverPath != null) {
        try {
          final coverFile = File(coverPath);
          if (await coverFile.exists()) {
            await coverFile.delete();
          }
        } catch (e) {
          _log.w('Failed to cleanup cover file: $e');
        }
      }
    } catch (e) {
      _log.e('Failed to embed metadata: $e');
    }
  }

  Future<void> _embedMetadataToMp3(
    String mp3Path,
    Track track, {
    String? genre,
    String? label,
    String? copyright,
  }) async {
    final settings = ref.read(settingsProvider);

    String? coverPath;
    var coverUrl = track.coverUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      try {
        if (settings.maxQualityCover) {
          coverUrl = _upgradeToMaxQualityCover(coverUrl);
          _log.d('Cover URL upgraded to max quality for MP3: $coverUrl');
        }

        final tempDir = await getTemporaryDirectory();
        final uniqueId =
            '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
        coverPath = '${tempDir.path}/cover_mp3_$uniqueId.jpg';

        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(coverUrl));
        final response = await request.close();
        if (response.statusCode == 200) {
          final file = File(coverPath);
          final sink = file.openWrite();
          await response.pipe(sink);
          await sink.close();
          _log.d('Cover downloaded for MP3: $coverPath');
        } else {
          _log.w(
            'Failed to download cover for MP3: HTTP ${response.statusCode}',
          );
          coverPath = null;
        }
        httpClient.close();
      } catch (e) {
        _log.e('Failed to download cover for MP3: $e');
        coverPath = null;
      }
    }

    try {
      final metadata = <String, String>{
        'TITLE': track.name,
        'ARTIST': track.artistName,
        'ALBUM': track.albumName,
      };

      final albumArtist =
          _normalizeOptionalString(track.albumArtist) ?? track.artistName;
      metadata['ALBUMARTIST'] = albumArtist;

      if (track.trackNumber != null) {
        metadata['TRACKNUMBER'] = track.trackNumber.toString();
        metadata['TRACK'] = track.trackNumber.toString();
      }

      if (track.discNumber != null) {
        metadata['DISCNUMBER'] = track.discNumber.toString();
        metadata['DISC'] = track.discNumber.toString();
      }

      if (track.releaseDate != null) {
        metadata['DATE'] = track.releaseDate!;
        metadata['YEAR'] = track.releaseDate!.split('-').first;
      }

      if (track.isrc != null) {
        metadata['ISRC'] = track.isrc!;
      }

      if (genre != null && genre.isNotEmpty) {
        metadata['GENRE'] = genre;
        _log.d('Adding GENRE to MP3: $genre');
      }
      if (label != null && label.isNotEmpty) {
        metadata['ORGANIZATION'] = label;
        _log.d('Adding ORGANIZATION (label) to MP3: $label');
      }
      if (copyright != null && copyright.isNotEmpty) {
        metadata['COPYRIGHT'] = copyright;
        _log.d('Adding COPYRIGHT to MP3: $copyright');
      }

      _log.d('MP3 Metadata map content: $metadata');

      final lyricsMode = settings.lyricsMode;
      final shouldEmbed = lyricsMode == 'embed' || lyricsMode == 'both';
      final shouldSaveExternal =
          lyricsMode == 'external' || lyricsMode == 'both';

      if (settings.embedLyrics && (shouldEmbed || shouldSaveExternal)) {
        try {
          final durationMs = track.duration * 1000;

          final lrcContent = await PlatformBridge.getLyricsLRC(
            track.id,
            track.name,
            track.artistName,
            filePath: '',
            durationMs: durationMs,
          );

          if (lrcContent.isNotEmpty) {
            if (shouldEmbed) {
              metadata['LYRICS'] = lrcContent;
              metadata['UNSYNCEDLYRICS'] = lrcContent;
              _log.d(
                'Lyrics fetched for MP3 embedding (${lrcContent.length} chars)',
              );
            }

            if (shouldSaveExternal) {
              try {
                final lrcPath = mp3Path.replaceAll(
                  RegExp(r'\.mp3$', caseSensitive: false),
                  '.lrc',
                );
                await File(lrcPath).writeAsString(lrcContent);
                _log.d('External LRC file saved: $lrcPath');
              } catch (e) {
                _log.w('Failed to save external LRC file: $e');
              }
            }
          }
        } catch (e) {
          _log.w('Failed to fetch lyrics for MP3: $e');
        }
      }

      _log.d('Embedding tags to MP3: $metadata');

      final result = await FFmpegService.embedMetadataToMp3(
        mp3Path: mp3Path,
        coverPath: coverPath != null && await File(coverPath).exists()
            ? coverPath
            : null,
        metadata: metadata,
      );

      if (result != null) {
        _log.d('Metadata, lyrics, and cover embedded to MP3 via FFmpeg');
      } else {
        _log.w('FFmpeg MP3 metadata/cover embed failed');
      }

      if (coverPath != null) {
        try {
          final coverFile = File(coverPath);
          if (await coverFile.exists()) {
            await coverFile.delete();
          }
        } catch (e) {
          _log.w('Failed to cleanup MP3 cover file: $e');
        }
      }
    } catch (e) {
      _log.e('Failed to embed metadata to MP3: $e');
    }
  }

  Future<void> _embedMetadataToOpus(
    String opusPath,
    Track track, {
    String? genre,
    String? label,
    String? copyright,
  }) async {
    final settings = ref.read(settingsProvider);

    String? coverPath;
    var coverUrl = track.coverUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      try {
        if (settings.maxQualityCover) {
          coverUrl = _upgradeToMaxQualityCover(coverUrl);
          _log.d('Cover URL upgraded to max quality for Opus: $coverUrl');
        }

        final tempDir = await getTemporaryDirectory();
        final uniqueId =
            '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
        coverPath = '${tempDir.path}/cover_opus_$uniqueId.jpg';

        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(coverUrl));
        final response = await request.close();
        if (response.statusCode == 200) {
          final file = File(coverPath);
          final sink = file.openWrite();
          await response.pipe(sink);
          await sink.close();
          _log.d('Cover downloaded for Opus: $coverPath');
        } else {
          _log.w(
            'Failed to download cover for Opus: HTTP ${response.statusCode}',
          );
          coverPath = null;
        }
        httpClient.close();
      } catch (e) {
        _log.e('Failed to download cover for Opus: $e');
        coverPath = null;
      }
    }

    try {
      final metadata = <String, String>{
        'TITLE': track.name,
        'ARTIST': track.artistName,
        'ALBUM': track.albumName,
      };

      final albumArtist =
          _normalizeOptionalString(track.albumArtist) ?? track.artistName;
      metadata['ALBUMARTIST'] = albumArtist;

      if (track.trackNumber != null) {
        metadata['TRACKNUMBER'] = track.trackNumber.toString();
      }

      if (track.discNumber != null) {
        metadata['DISCNUMBER'] = track.discNumber.toString();
      }

      if (track.releaseDate != null) {
        metadata['DATE'] = track.releaseDate!;
      }

      if (track.isrc != null) {
        metadata['ISRC'] = track.isrc!;
      }

      if (genre != null && genre.isNotEmpty) {
        metadata['GENRE'] = genre;
        _log.d('Adding GENRE to Opus: $genre');
      }
      if (label != null && label.isNotEmpty) {
        metadata['ORGANIZATION'] = label;
        _log.d('Adding ORGANIZATION (label) to Opus: $label');
      }
      if (copyright != null && copyright.isNotEmpty) {
        metadata['COPYRIGHT'] = copyright;
        _log.d('Adding COPYRIGHT to Opus: $copyright');
      }

      _log.d('Opus Metadata map content: $metadata');

      final lyricsMode = settings.lyricsMode;
      final shouldEmbed = lyricsMode == 'embed' || lyricsMode == 'both';
      final shouldSaveExternal =
          lyricsMode == 'external' || lyricsMode == 'both';

      if (settings.embedLyrics && (shouldEmbed || shouldSaveExternal)) {
        try {
          final durationMs = track.duration * 1000;

          final lrcContent = await PlatformBridge.getLyricsLRC(
            track.id,
            track.name,
            track.artistName,
            filePath: '',
            durationMs: durationMs,
          );

          if (lrcContent.isNotEmpty) {
            if (shouldEmbed) {
              metadata['LYRICS'] = lrcContent;
              _log.d(
                'Lyrics fetched for Opus embedding (${lrcContent.length} chars)',
              );
            }

            if (shouldSaveExternal) {
              try {
                final lrcPath = opusPath.replaceAll(
                  RegExp(r'\.opus$', caseSensitive: false),
                  '.lrc',
                );
                await File(lrcPath).writeAsString(lrcContent);
                _log.d('External LRC file saved: $lrcPath');
              } catch (e) {
                _log.w('Failed to save external LRC file: $e');
              }
            }
          }
        } catch (e) {
          _log.w('Failed to fetch lyrics for Opus: $e');
        }
      }

      _log.d('Embedding tags to Opus: $metadata');

      final result = await FFmpegService.embedMetadataToOpus(
        opusPath: opusPath,
        coverPath: coverPath != null && await File(coverPath).exists()
            ? coverPath
            : null,
        metadata: metadata,
      );

      if (result != null) {
        _log.d('Metadata, lyrics, and cover embedded to Opus via FFmpeg');
      } else {
        _log.w('FFmpeg Opus metadata/cover embed failed');
      }

      if (coverPath != null) {
        try {
          final coverFile = File(coverPath);
          if (await coverFile.exists()) {
            await coverFile.delete();
          }
        } catch (e) {
          _log.w('Failed to cleanup Opus cover file: $e');
        }
      }
    } catch (e) {
      _log.e('Failed to embed metadata to Opus: $e');
    }
  }

  Future<String?> _copySafToTemp(String uri) async {
    try {
      return await PlatformBridge.copyContentUriToTemp(uri);
    } catch (e) {
      _log.w('Failed to copy SAF uri to temp: $e');
      return null;
    }
  }

  Future<String?> _writeTempToSaf({
    required String treeUri,
    required String relativeDir,
    required String fileName,
    required String mimeType,
    required String srcPath,
  }) async {
    try {
      return await PlatformBridge.createSafFileFromPath(
        treeUri: treeUri,
        relativeDir: relativeDir,
        fileName: fileName,
        mimeType: mimeType,
        srcPath: srcPath,
      );
    } catch (e) {
      _log.w('Failed to write temp file to SAF: $e');
      return null;
    }
  }

  Future<void> _writeLrcToSaf({
    required String treeUri,
    required String relativeDir,
    required String baseName,
    required String lrcContent,
  }) async {
    try {
      if (lrcContent.isEmpty) return;
      final tempDir = await getTemporaryDirectory();
      final tempPath = '${tempDir.path}/$baseName.lrc';
      await File(tempPath).writeAsString(lrcContent);
      final lrcName = '$baseName.lrc';
      final uri = await _writeTempToSaf(
        treeUri: treeUri,
        relativeDir: relativeDir,
        fileName: lrcName,
        mimeType: _mimeTypeForExt('.lrc'),
        srcPath: tempPath,
      );
      if (uri != null) {
        _log.d('External LRC saved to SAF: $lrcName');
      } else {
        _log.w('Failed to write external LRC to SAF');
      }
      try {
        await File(tempPath).delete();
      } catch (_) {}
    } catch (e) {
      _log.w('Failed to create external LRC in SAF: $e');
    }
  }

  Future<void> _deleteSafFile(String uri) async {
    try {
      await PlatformBridge.safDelete(uri);
    } catch (e) {
      _log.w('Failed to delete SAF file: $e');
    }
  }

  Future<void> _processQueue() async {
    if (state.isProcessing) return;

    // Check network connectivity before starting
    final settings = ref.read(settingsProvider);
    updateSettings(settings);
    final isSafMode = _isSafMode(settings);
    if (settings.downloadNetworkMode == 'wifi_only') {
      final connectivityResult = await Connectivity().checkConnectivity();
      final hasWifi = connectivityResult.contains(ConnectivityResult.wifi);
      if (!hasWifi) {
        _log.w('WiFi-only mode enabled but no WiFi connection. Queue paused.');
        state = state.copyWith(isProcessing: false, isPaused: true);
        return;
      }
    }

    state = state.copyWith(isProcessing: true);
    _log.i('Starting queue processing...');

    _totalQueuedAtStart = state.items
        .where((i) => i.status == DownloadStatus.queued)
        .length;
    _completedInSession = 0;
    _failedInSession = 0;

    if (Platform.isAndroid && _totalQueuedAtStart > 0) {
      final firstItem = state.items.firstWhere(
        (item) => item.status == DownloadStatus.queued,
        orElse: () => state.items.first,
      );
      try {
        await PlatformBridge.startDownloadService(
          trackName: firstItem.track.name,
          artistName: firstItem.track.artistName,
          queueCount: _totalQueuedAtStart,
        );
        _log.d('Foreground service started');
      } catch (e) {
        _log.e('Failed to start foreground service: $e');
      }
    }

    if (!isSafMode && state.outputDir.isEmpty) {
      _log.d('Output dir empty, initializing...');
      await _initOutputDir();
    }

    // iOS: Validate that outputDir is writable (not iCloud Drive which Go can't access)
    if (!isSafMode && Platform.isIOS && state.outputDir.isNotEmpty) {
      final isICloudPath =
          state.outputDir.contains('Mobile Documents') ||
          state.outputDir.contains('CloudDocs') ||
          state.outputDir.contains('com~apple~CloudDocs');
      if (isICloudPath) {
        _log.w(
          'iOS: iCloud Drive path detected, falling back to app Documents folder',
        );
        _log.w('Go backend cannot write to iCloud Drive due to iOS sandboxing');
        final dir = await getApplicationDocumentsDirectory();
        final musicDir = Directory('${dir.path}/SpotiFLAC');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
        state = state.copyWith(outputDir: musicDir.path);
      } else if (!isValidIosWritablePath(state.outputDir)) {
        // Check for other invalid paths (like container root without Documents/)
        _log.w(
          'iOS: Invalid output path detected (container root?), falling back to app Documents folder',
        );
        _log.w('Original path: ${state.outputDir}');
        final correctedPath = await validateOrFixIosPath(state.outputDir);
        _log.i('Corrected path: $correctedPath');
        state = state.copyWith(outputDir: correctedPath);
      }
    }

    if (!isSafMode && state.outputDir.isEmpty) {
      _log.d('Using fallback directory...');
      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/SpotiFLAC');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      state = state.copyWith(outputDir: musicDir.path);
    }

    if (!isSafMode) {
      _log.d('Output directory: ${state.outputDir}');
    } else {
      _log.d('Output directory: SAF (tree_uri=${settings.downloadTreeUri})');
      // Validate SAF permission is still accessible
      try {
        final testResult = await PlatformBridge.createSafFileFromPath(
          treeUri: settings.downloadTreeUri,
          relativeDir: '',
          fileName: '.spotiflac_test',
          mimeType: 'application/octet-stream',
          srcPath: '',
        );
        // If we got a result, permission is valid (file creation may fail but that's ok)
        // If permission is revoked, this will throw
        if (testResult != null) {
          // Clean up test file
          await PlatformBridge.safDelete(testResult);
        }
      } catch (e) {
        _log.e('SAF permission validation failed: $e');
        _log.w('SAF tree URI may be invalid or permission revoked');
        // Mark all queued items as failed
        for (final item in state.items) {
          if (item.status == DownloadStatus.queued) {
            updateItemStatus(
              item.id,
              DownloadStatus.failed,
              error:
                  'SAF permission invalid or revoked. Please reconfigure download location in Settings.',
            );
          }
        }
        state = state.copyWith(isProcessing: false);
        return;
      }
    }
    _log.d('Concurrent downloads: ${state.concurrentDownloads}');
    await _processQueueParallel();

    _stopProgressPolling();

    if (Platform.isAndroid) {
      try {
        await PlatformBridge.stopDownloadService();
        _log.d('Foreground service stopped');
      } catch (e) {
        _log.e('Failed to stop foreground service: $e');
      }
    }

    if (_downloadCount > 0) {
      _log.d('Final connection cleanup...');
      try {
        await PlatformBridge.cleanupConnections();
      } catch (e) {
        _log.e('Final cleanup failed: $e');
      }
      _downloadCount = 0;
    }

    _log.i(
      'Queue stats - completed: $_completedInSession, failed: $_failedInSession, totalAtStart: $_totalQueuedAtStart',
    );
    if (_totalQueuedAtStart > 0) {
      await _notificationService.showQueueComplete(
        completedCount: _completedInSession,
        failedCount: _failedInSession,
      );

      // Auto-export failed downloads if enabled
      final settings = ref.read(settingsProvider);
      if (settings.autoExportFailedDownloads && _failedInSession > 0) {
        final exportPath = await exportFailedDownloads();
        if (exportPath != null) {
          _log.i('Auto-exported failed downloads to: $exportPath');
        }
      }
    }

    _log.i('Queue processing finished');
    state = state.copyWith(isProcessing: false, currentDownload: null);

    final hasQueuedItems = state.items.any(
      (item) => item.status == DownloadStatus.queued,
    );
    if (hasQueuedItems) {
      _log.i(
        'Found queued items after processing finished, restarting queue...',
      );
      Future.microtask(() => _processQueue());
    }
  }

  Future<void> _processQueueParallel() async {
    final activeDownloads = <String, Future<void>>{};
    var lastLoggedMaxConcurrent = -1;

    _startMultiProgressPolling();

    while (true) {
      if (state.isPaused) {
        _log.d('Queue is paused, waiting for active downloads...');
        await Future.delayed(_queueSchedulingInterval);
        continue;
      }

      final maxConcurrent = max(1, state.concurrentDownloads);
      if (lastLoggedMaxConcurrent != maxConcurrent) {
        _log.d('Parallel worker max concurrency now: $maxConcurrent');
        lastLoggedMaxConcurrent = maxConcurrent;
      }

      final queuedItems = state.items
          .where((item) => item.status == DownloadStatus.queued)
          .toList();

      if (queuedItems.isEmpty && activeDownloads.isEmpty) {
        _log.d('No more items to process');
        break;
      }

      while (activeDownloads.length < maxConcurrent &&
          queuedItems.isNotEmpty &&
          !state.isPaused) {
        final item = queuedItems.removeAt(0);

        updateItemStatus(item.id, DownloadStatus.downloading);

        final future = _downloadSingleItem(item).whenComplete(() {
          activeDownloads.remove(item.id);
          PlatformBridge.clearItemProgress(item.id).catchError((_) {});
        });

        activeDownloads[item.id] = future;
        _log.d(
          'Started parallel download: ${item.track.name} (${activeDownloads.length}/$maxConcurrent active)',
        );
      }

      if (activeDownloads.isNotEmpty) {
        // Re-check queue/settings periodically so concurrency changes
        // (e.g. 1 -> 3) can take effect before any active item finishes.
        await Future.any([
          Future.any(activeDownloads.values),
          Future.delayed(_queueSchedulingInterval),
        ]);
      } else {
        await Future.delayed(_queueSchedulingInterval);
      }
    }

    if (activeDownloads.isNotEmpty) {
      await Future.wait(activeDownloads.values);
    }

    _stopProgressPolling();
  }

  Future<void> _downloadSingleItem(DownloadItem item) async {
    _log.d('Processing: ${item.track.name} by ${item.track.artistName}');
    _log.d('Cover URL: ${item.track.coverUrl}');

    final currentItem = state.items.firstWhere(
      (i) => i.id == item.id,
      orElse: () => item,
    );
    if (currentItem.status == DownloadStatus.skipped) {
      _log.i('Download was cancelled before start, skipping');
      return;
    }

    state = state.copyWith(currentDownload: item);

    updateItemStatus(item.id, DownloadStatus.downloading);

    try {
      final settings = ref.read(settingsProvider);

      Track trackToDownload = item.track;
      final needsEnrichment =
          trackToDownload.id.startsWith('deezer:') &&
          (trackToDownload.isrc == null ||
              trackToDownload.isrc!.isEmpty ||
              trackToDownload.trackNumber == null ||
              trackToDownload.trackNumber == 0);

      if (needsEnrichment) {
        try {
          _log.d(
            'Enriching incomplete metadata for Deezer track: ${trackToDownload.name}',
          );
          _log.d(
            'Current ISRC: ${trackToDownload.isrc}, TrackNumber: ${trackToDownload.trackNumber}',
          );
          final rawId = trackToDownload.id.split(':')[1];
          _log.d('Fetching full metadata for Deezer ID: $rawId');
          final fullData = await PlatformBridge.getDeezerMetadata(
            'track',
            rawId,
          );
          _log.d('Got response keys: ${fullData.keys.toList()}');

          if (fullData.containsKey('track')) {
            final trackData = fullData['track'];
            _log.d('Track data type: ${trackData.runtimeType}');
            if (trackData is Map<String, dynamic>) {
              final data = trackData;
              _log.d('Track data keys: ${data.keys.toList()}');
              _log.d('ISRC from API: ${data['isrc']}');
              _log.d('album_type from API: ${data['album_type']}');
              trackToDownload = Track(
                id: (data['spotify_id'] as String?) ?? trackToDownload.id,
                name: (data['name'] as String?) ?? trackToDownload.name,
                artistName:
                    (data['artists'] as String?) ?? trackToDownload.artistName,
                albumName:
                    (data['album_name'] as String?) ??
                    trackToDownload.albumName,
                albumArtist: data['album_artist'] as String?,
                coverUrl: data['images'] as String?,
                duration:
                    ((data['duration_ms'] as int?) ??
                        (trackToDownload.duration * 1000)) ~/
                    1000,
                isrc: (data['isrc'] as String?) ?? trackToDownload.isrc,
                trackNumber: data['track_number'] as int?,
                discNumber: data['disc_number'] as int?,
                releaseDate: data['release_date'] as String?,
                deezerId: rawId,
                availability: trackToDownload.availability,
                albumType:
                    (data['album_type'] as String?) ??
                    trackToDownload.albumType,
                source: trackToDownload.source,
              );
              _log.d(
                'Metadata enriched: Track ${trackToDownload.trackNumber}, Disc ${trackToDownload.discNumber}, ISRC ${trackToDownload.isrc}, AlbumType ${trackToDownload.albumType}',
              );
            } else {
              _log.w('Unexpected track data type: ${trackData.runtimeType}');
            }
          } else {
            _log.w('Response does not contain track key');
          }
        } catch (e, stack) {
          _log.w('Failed to enrich metadata: $e');
          _log.w('Stack trace: $stack');
        }
      }

      _log.d('Track coverUrl after enrichment: ${trackToDownload.coverUrl}');

      final normalizedAlbumArtist = _normalizeOptionalString(
        trackToDownload.albumArtist,
      );

      final quality = item.qualityOverride ?? state.audioQuality;
      final isSafMode = _isSafMode(settings);
      final relativeOutputDir = isSafMode
          ? await _buildRelativeOutputDir(
              trackToDownload,
              settings.folderOrganization,
              separateSingles: settings.separateSingles,
              albumFolderStructure: settings.albumFolderStructure,
              useAlbumArtistForFolders: settings.useAlbumArtistForFolders,
              usePrimaryArtistOnly: settings.usePrimaryArtistOnly,
            )
          : '';
      String? appOutputDir;
      final initialOutputDir = isSafMode
          ? relativeOutputDir
          : await _buildOutputDir(
              trackToDownload,
              settings.folderOrganization,
              separateSingles: settings.separateSingles,
              albumFolderStructure: settings.albumFolderStructure,
              useAlbumArtistForFolders: settings.useAlbumArtistForFolders,
              usePrimaryArtistOnly: settings.usePrimaryArtistOnly,
            );
      var effectiveOutputDir = initialOutputDir;
      var effectiveSafMode = isSafMode;

      String? safFileName;
      String? safBaseName;
      String safOutputExt = _determineOutputExt(quality, item.service);
      if (isSafMode) {
        final baseName =
            await PlatformBridge.buildFilename(state.filenameFormat, {
              'title': trackToDownload.name,
              'artist': trackToDownload.artistName,
              'album': trackToDownload.albumName,
              'track': trackToDownload.trackNumber ?? 0,
              'disc': trackToDownload.discNumber ?? 0,
              'year': _extractYear(trackToDownload.releaseDate) ?? '',
            });
        final sanitized = await PlatformBridge.sanitizeFilename(baseName);
        safBaseName = sanitized;
        safFileName = '$sanitized$safOutputExt';
      }
      String? finalSafFileName = safFileName;

      String? genre;
      String? label;

      String? deezerTrackId = trackToDownload.deezerId;
      if (deezerTrackId == null && trackToDownload.id.startsWith('deezer:')) {
        deezerTrackId = trackToDownload.id.split(':')[1];
      }
      if (deezerTrackId == null &&
          trackToDownload.availability?.deezerId != null) {
        deezerTrackId = trackToDownload.availability!.deezerId;
      }

      if (deezerTrackId == null &&
          trackToDownload.isrc != null &&
          trackToDownload.isrc!.isNotEmpty &&
          _isValidISRC(trackToDownload.isrc!)) {
        try {
          _log.d('No Deezer ID, searching by ISRC: ${trackToDownload.isrc}');
          final deezerResult = await PlatformBridge.searchDeezerByISRC(
            trackToDownload.isrc!,
          );
          if (deezerResult['success'] == true &&
              deezerResult['track_id'] != null) {
            deezerTrackId = deezerResult['track_id'].toString();
            _log.d('Found Deezer track ID via ISRC: $deezerTrackId');
          }
        } catch (e) {
          _log.w('Failed to search Deezer by ISRC: $e');
        }
      }

      // Fallback: Use SongLink to convert Spotify ID to Deezer ID
      if (deezerTrackId == null &&
          trackToDownload.id.isNotEmpty &&
          !trackToDownload.id.startsWith('deezer:') &&
          !trackToDownload.id.startsWith('extension:')) {
        try {
          // Extract clean Spotify ID (remove spotify: prefix if present)
          String spotifyId = trackToDownload.id;
          if (spotifyId.startsWith('spotify:track:')) {
            spotifyId = spotifyId.split(':').last;
          }
          _log.d(
            'No Deezer ID, converting from Spotify via SongLink: $spotifyId',
          );
          final deezerData = await PlatformBridge.convertSpotifyToDeezer(
            'track',
            spotifyId,
          );
          // Response is TrackResponse: {"track": {"spotify_id": "deezer:XXXXX", ...}}
          final trackData = deezerData['track'];
          if (trackData is Map<String, dynamic>) {
            final rawId = trackData['spotify_id'] as String?;
            if (rawId != null && rawId.startsWith('deezer:')) {
              deezerTrackId = rawId.split(':')[1];
              _log.d('Found Deezer track ID via SongLink: $deezerTrackId');
            } else if (deezerData['id'] != null) {
              deezerTrackId = deezerData['id'].toString();
              _log.d(
                'Found Deezer track ID via SongLink (legacy): $deezerTrackId',
              );
            }

            // Enrich track metadata from Deezer response (release_date, isrc, etc.)
            final deezerReleaseDate = _normalizeOptionalString(
              trackData['release_date'] as String?,
            );
            final deezerIsrc = _normalizeOptionalString(
              trackData['isrc'] as String?,
            );
            final deezerTrackNum = trackData['track_number'] as int?;
            final deezerDiscNum = trackData['disc_number'] as int?;

            final needsEnrich =
                (trackToDownload.releaseDate == null &&
                    deezerReleaseDate != null) ||
                (trackToDownload.isrc == null && deezerIsrc != null) ||
                (!_isValidISRC(trackToDownload.isrc ?? '') &&
                    deezerIsrc != null) ||
                (trackToDownload.trackNumber == null &&
                    deezerTrackNum != null) ||
                (trackToDownload.discNumber == null && deezerDiscNum != null);

            if (needsEnrich) {
              trackToDownload = Track(
                id: trackToDownload.id,
                name: trackToDownload.name,
                artistName: trackToDownload.artistName,
                albumName: trackToDownload.albumName,
                albumArtist: trackToDownload.albumArtist,
                coverUrl: trackToDownload.coverUrl,
                duration: trackToDownload.duration,
                isrc: (deezerIsrc != null && _isValidISRC(deezerIsrc))
                    ? deezerIsrc
                    : trackToDownload.isrc,
                trackNumber: trackToDownload.trackNumber ?? deezerTrackNum,
                discNumber: trackToDownload.discNumber ?? deezerDiscNum,
                releaseDate: trackToDownload.releaseDate ?? deezerReleaseDate,
                deezerId: deezerTrackId,
                availability: trackToDownload.availability,
                albumType: trackToDownload.albumType,
                source: trackToDownload.source,
              );
              _log.d(
                'Enriched track from Deezer - date: ${trackToDownload.releaseDate}, ISRC: ${trackToDownload.isrc}, track: ${trackToDownload.trackNumber}, disc: ${trackToDownload.discNumber}',
              );
            }
          } else if (deezerData['id'] != null) {
            deezerTrackId = deezerData['id'].toString();
            _log.d('Found Deezer track ID via SongLink (flat): $deezerTrackId');
          }
        } catch (e) {
          _log.w('Failed to convert Spotify to Deezer via SongLink: $e');
        }
      }

      if (deezerTrackId != null && deezerTrackId.isNotEmpty) {
        try {
          final extendedMetadata =
              await PlatformBridge.getDeezerExtendedMetadata(deezerTrackId);
          if (extendedMetadata != null) {
            genre = extendedMetadata['genre'];
            label = extendedMetadata['label'];
            if (genre != null && genre.isNotEmpty) {
              _log.d('Extended metadata - Genre: $genre, Label: $label');
            }
          }
        } catch (e) {
          _log.w('Failed to fetch extended metadata from Deezer: $e');
        }
      }

      Map<String, dynamic> result;

      final extensionState = ref.read(extensionProvider);
      final hasActiveExtensions = extensionState.extensions.any(
        (e) => e.enabled,
      );
      final useExtensions =
          settings.useExtensionProviders && hasActiveExtensions;

      Future<Map<String, dynamic>> runDownload({
        required bool useSaf,
        required String outputDir,
      }) async {
        final storageMode = useSaf ? 'saf' : 'app';
        final treeUri = useSaf ? settings.downloadTreeUri : '';
        final relativeDir = useSaf ? outputDir : '';
        final fileName = useSaf ? (safFileName ?? '') : '';
        final outputExt = useSaf ? safOutputExt : '';
        final isYouTube = item.service == 'youtube';
        final shouldUseExtensions = !isYouTube && useExtensions;
        final shouldUseFallback =
            !isYouTube && !shouldUseExtensions && state.autoFallback;

        if (isYouTube) {
          _log.d('Using YouTube/Cobalt provider for download');
          _log.d('Quality: $quality (lossy only)');
        } else if (shouldUseExtensions) {
          _log.d('Using extension providers for download');
          _log.d(
            'Quality: $quality${item.qualityOverride != null ? ' (override)' : ''}',
          );
        } else if (shouldUseFallback) {
          _log.d('Using auto-fallback mode');
          _log.d(
            'Quality: $quality${item.qualityOverride != null ? ' (override)' : ''}',
          );
        }
        _log.d('Output dir: $outputDir');

        final payload = DownloadRequestPayload(
          isrc: trackToDownload.isrc ?? '',
          service: item.service,
          spotifyId: trackToDownload.id,
          trackName: trackToDownload.name,
          artistName: trackToDownload.artistName,
          albumName: trackToDownload.albumName,
          albumArtist: normalizedAlbumArtist ?? trackToDownload.artistName,
          coverUrl: trackToDownload.coverUrl ?? '',
          outputDir: outputDir,
          filenameFormat: state.filenameFormat,
          quality: quality,
          // Keep prior behavior: non-YouTube paths were implicitly true.
          embedLyrics: isYouTube ? settings.embedLyrics : true,
          embedMaxQualityCover: settings.maxQualityCover,
          trackNumber: trackToDownload.trackNumber ?? 1,
          discNumber: trackToDownload.discNumber ?? 1,
          releaseDate: trackToDownload.releaseDate ?? '',
          itemId: item.id,
          durationMs: trackToDownload.duration,
          source: trackToDownload.source ?? '',
          genre: genre ?? '',
          label: label ?? '',
          deezerId: deezerTrackId ?? '',
          lyricsMode: settings.lyricsMode,
          storageMode: storageMode,
          safTreeUri: treeUri,
          safRelativeDir: relativeDir,
          safFileName: fileName,
          safOutputExt: outputExt,
        );

        return PlatformBridge.downloadByStrategy(
          payload: payload,
          useExtensions: shouldUseExtensions,
          useFallback: shouldUseFallback,
        );
      }

      result = await runDownload(
        useSaf: effectiveSafMode,
        outputDir: effectiveOutputDir,
      );

      if (effectiveSafMode &&
          result['success'] != true &&
          _isSafWriteFailure(result)) {
        _log.w('SAF write failed, retrying with app-private storage');
        appOutputDir ??= await _buildOutputDir(
          trackToDownload,
          settings.folderOrganization,
          separateSingles: settings.separateSingles,
          albumFolderStructure: settings.albumFolderStructure,
          useAlbumArtistForFolders: settings.useAlbumArtistForFolders,
          usePrimaryArtistOnly: settings.usePrimaryArtistOnly,
        );
        final fallbackResult = await runDownload(
          useSaf: false,
          outputDir: appOutputDir,
        );
        if (fallbackResult['success'] == true) {
          effectiveSafMode = false;
          effectiveOutputDir = appOutputDir;
          finalSafFileName = null;
          result = fallbackResult;
        }
      }

      _log.d('Result: $result');

      final currentItem = state.items.firstWhere(
        (i) => i.id == item.id,
        orElse: () => item,
      );
      if (currentItem.status == DownloadStatus.skipped) {
        _log.i('Download was cancelled, skipping result processing');
        final filePath = result['file_path'] as String?;
        if (filePath != null && result['success'] == true) {
          await deleteFile(filePath);
          _log.d('Deleted cancelled download file: $filePath');
        }
        return;
      }

      if (result['success'] == true) {
        var filePath = result['file_path'] as String?;
        final reportedFileName = result['file_name'] as String?;
        if (effectiveSafMode &&
            reportedFileName != null &&
            reportedFileName.isNotEmpty) {
          finalSafFileName = reportedFileName;
        }

        // Check if file already existed (detected via ISRC match in Go backend)
        final wasExisting = result['already_exists'] == true;
        if (wasExisting) {
          _log.i('File already exists in library: $filePath');
        }

        _log.i('Download success, file: $filePath');

        final actualBitDepth = result['actual_bit_depth'] as int?;
        final actualSampleRate = result['actual_sample_rate'] as int?;
        String actualQuality = quality;

        if (actualBitDepth != null && actualBitDepth > 0) {
          // Format: "24-bit/96kHz" or "16-bit/44.1kHz"
          final sampleRateKHz = actualSampleRate != null && actualSampleRate > 0
              ? (actualSampleRate / 1000).toStringAsFixed(
                  actualSampleRate % 1000 == 0 ? 0 : 1,
                )
              : '?';
          actualQuality = '$actualBitDepth-bit/${sampleRateKHz}kHz';
          _log.i('Actual quality: $actualQuality');
        }

        final actualService =
            ((result['service'] as String?)?.toLowerCase()) ??
            item.service.toLowerCase();
        final decryptionKey =
            (result['decryption_key'] as String?)?.trim() ?? '';

        if (!wasExisting &&
            decryptionKey.isNotEmpty &&
            filePath != null &&
            actualService == 'amazon') {
          _log.i('Amazon encrypted stream detected, decrypting via FFmpeg...');
          updateItemStatus(item.id, DownloadStatus.downloading, progress: 0.9);

          if (effectiveSafMode && isContentUri(filePath)) {
            final currentFilePath = filePath;
            final tempPath = await _copySafToTemp(currentFilePath);
            if (tempPath == null) {
              _log.e('Failed to copy encrypted SAF file to temp for decrypt');
              updateItemStatus(
                item.id,
                DownloadStatus.failed,
                error: 'Failed to access encrypted SAF file',
                errorType: DownloadErrorType.unknown,
              );
              return;
            }

            String? decryptedTempPath;
            try {
              decryptedTempPath = await FFmpegService.decryptAudioFile(
                inputPath: tempPath,
                decryptionKey: decryptionKey,
                deleteOriginal: false,
              );
              if (decryptedTempPath == null) {
                _log.e('FFmpeg decrypt failed for SAF file');
                updateItemStatus(
                  item.id,
                  DownloadStatus.failed,
                  error: 'Failed to decrypt Amazon stream',
                  errorType: DownloadErrorType.unknown,
                );
                return;
              }

              final dotIndex = decryptedTempPath.lastIndexOf('.');
              final decryptedExt = dotIndex >= 0
                  ? decryptedTempPath.substring(dotIndex).toLowerCase()
                  : '.flac';
              final allowedExt = <String>{'.flac', '.m4a', '.mp3', '.opus'};
              final finalExt = allowedExt.contains(decryptedExt)
                  ? decryptedExt
                  : '.flac';

              final newFileName = '${safBaseName ?? 'track'}$finalExt';
              final newUri = await _writeTempToSaf(
                treeUri: settings.downloadTreeUri,
                relativeDir: effectiveOutputDir,
                fileName: newFileName,
                mimeType: _mimeTypeForExt(finalExt),
                srcPath: decryptedTempPath,
              );

              if (newUri == null) {
                _log.e('Failed to write decrypted Amazon stream back to SAF');
                updateItemStatus(
                  item.id,
                  DownloadStatus.failed,
                  error: 'Failed to write decrypted file to storage',
                  errorType: DownloadErrorType.unknown,
                );
                return;
              }

              if (newUri != currentFilePath) {
                await _deleteSafFile(currentFilePath);
              }
              filePath = newUri;
              finalSafFileName = newFileName;
              _log.i('Amazon SAF decryption completed');
            } finally {
              try {
                await File(tempPath).delete();
              } catch (_) {}
              if (decryptedTempPath != null && decryptedTempPath != tempPath) {
                try {
                  await File(decryptedTempPath).delete();
                } catch (_) {}
              }
            }
          } else {
            final decryptedPath = await FFmpegService.decryptAudioFile(
              inputPath: filePath,
              decryptionKey: decryptionKey,
              deleteOriginal: true,
            );
            if (decryptedPath == null) {
              _log.e('FFmpeg decrypt failed for local file');
              updateItemStatus(
                item.id,
                DownloadStatus.failed,
                error: 'Failed to decrypt Amazon stream',
                errorType: DownloadErrorType.unknown,
              );
              try {
                await deleteFile(filePath);
              } catch (_) {}
              return;
            }
            filePath = decryptedPath;
            _log.i('Amazon local decryption completed');
          }
        }

        final isContentUriPath = filePath != null && isContentUri(filePath);
        final mimeType = isContentUriPath
            ? await _getSafMimeType(filePath)
            : null;
        final isM4aFile =
            filePath != null &&
            (filePath.endsWith('.m4a') ||
                (mimeType != null && mimeType.contains('mp4')));
        final isFlacFile =
            filePath != null &&
            (filePath.endsWith('.flac') ||
                (mimeType != null && mimeType.contains('flac')));
        final shouldForceTidalSafM4aHandling =
            !wasExisting &&
            isContentUriPath &&
            effectiveSafMode &&
            actualService == 'tidal' &&
            quality != 'HIGH' &&
            filePath.endsWith('.flac') &&
            (mimeType == null || mimeType.contains('flac'));

        if (shouldForceTidalSafM4aHandling) {
          _log.w(
            'Tidal SAF file is labeled FLAC but backend returned DASH/M4A stream; forcing FFmpeg conversion to FLAC.',
          );
        }

        if (isM4aFile || shouldForceTidalSafM4aHandling) {
          // At this point filePath is guaranteed non-null by the checks above.
          final currentFilePath = filePath;

          if (isContentUriPath && effectiveSafMode) {
            if (quality == 'HIGH') {
              final tidalHighFormat = settings.tidalHighFormat;
              _log.i(
                'Tidal HIGH quality (SAF), converting M4A to $tidalHighFormat...',
              );

              final tempPath = await _copySafToTemp(currentFilePath);
              if (tempPath != null) {
                String? convertedPath;
                try {
                  updateItemStatus(
                    item.id,
                    DownloadStatus.downloading,
                    progress: 0.95,
                  );

                  final format = tidalHighFormat.startsWith('opus')
                      ? 'opus'
                      : 'mp3';
                  convertedPath = await FFmpegService.convertM4aToLossy(
                    tempPath,
                    format: format,
                    bitrate: tidalHighFormat,
                    deleteOriginal: false,
                  );

                  if (convertedPath != null) {
                    _log.i(
                      'Successfully converted M4A to $format (temp): $convertedPath',
                    );
                    _log.i('Embedding metadata to $format...');
                    updateItemStatus(
                      item.id,
                      DownloadStatus.downloading,
                      progress: 0.99,
                    );

                    final backendGenre = result['genre'] as String?;
                    final backendLabel = result['label'] as String?;
                    final backendCopyright = result['copyright'] as String?;

                    if (format == 'mp3') {
                      await _embedMetadataToMp3(
                        convertedPath,
                        trackToDownload,
                        genre: backendGenre ?? genre,
                        label: backendLabel ?? label,
                        copyright: backendCopyright,
                      );
                    } else {
                      await _embedMetadataToOpus(
                        convertedPath,
                        trackToDownload,
                        genre: backendGenre ?? genre,
                        label: backendLabel ?? label,
                        copyright: backendCopyright,
                      );
                    }

                    final newExt = format == 'opus' ? '.opus' : '.mp3';
                    final newFileName = '${safBaseName ?? 'track'}$newExt';
                    final newUri = await _writeTempToSaf(
                      treeUri: settings.downloadTreeUri,
                      relativeDir: effectiveOutputDir,
                      fileName: newFileName,
                      mimeType: _mimeTypeForExt(newExt),
                      srcPath: convertedPath,
                    );

                    if (newUri != null) {
                      if (newUri != currentFilePath) {
                        await _deleteSafFile(currentFilePath);
                      }
                      filePath = newUri;
                      finalSafFileName = newFileName;
                      final bitrateDisplay = tidalHighFormat.contains('_')
                          ? '${tidalHighFormat.split('_').last}kbps'
                          : '320kbps';
                      actualQuality = '${format.toUpperCase()} $bitrateDisplay';
                    } else {
                      _log.w(
                        'Failed to write converted $format to SAF, keeping M4A',
                      );
                      actualQuality = 'AAC 320kbps';
                    }
                  } else {
                    _log.w(
                      'M4A to $format conversion failed, keeping M4A file',
                    );
                    actualQuality = 'AAC 320kbps';
                  }
                } catch (e) {
                  _log.w('SAF M4A conversion failed: $e');
                  actualQuality = 'AAC 320kbps';
                } finally {
                  // Clean up temp files
                  try {
                    await File(tempPath).delete();
                  } catch (_) {}
                  if (convertedPath != null) {
                    try {
                      await File(convertedPath).delete();
                    } catch (_) {}
                  }
                }
              }
            } else {
              _log.d('M4A file detected (SAF), converting to FLAC...');
              final tempPath = await _copySafToTemp(currentFilePath);
              if (tempPath != null) {
                String? flacPath;
                try {
                  final length = await File(tempPath).length();
                  if (length < 1024) {
                    _log.w('Temp M4A is too small (<1KB), skipping conversion');
                  } else {
                    updateItemStatus(
                      item.id,
                      DownloadStatus.downloading,
                      progress: 0.95,
                    );
                    flacPath = await FFmpegService.convertM4aToFlac(tempPath);
                    if (flacPath != null) {
                      _log.d('Converted to FLAC (temp): $flacPath');
                      _log.d(
                        'Embedding metadata and cover to converted FLAC...',
                      );
                      final finalTrack = _buildTrackForMetadataEmbedding(
                        trackToDownload,
                        result,
                        normalizedAlbumArtist,
                      );

                      final backendGenre = result['genre'] as String?;
                      final backendLabel = result['label'] as String?;
                      final backendCopyright = result['copyright'] as String?;

                      await _embedMetadataAndCover(
                        flacPath,
                        finalTrack,
                        genre: backendGenre ?? genre,
                        label: backendLabel ?? label,
                        copyright: backendCopyright,
                      );

                      final newFileName = '${safBaseName ?? 'track'}.flac';
                      final newUri = await _writeTempToSaf(
                        treeUri: settings.downloadTreeUri,
                        relativeDir: effectiveOutputDir,
                        fileName: newFileName,
                        mimeType: _mimeTypeForExt('.flac'),
                        srcPath: flacPath,
                      );

                      if (newUri != null) {
                        if (newUri != currentFilePath) {
                          await _deleteSafFile(currentFilePath);
                        }
                        filePath = newUri;
                        finalSafFileName = newFileName;
                      } else {
                        _log.w('Failed to write FLAC to SAF, keeping M4A');
                      }
                    } else {
                      _log.w(
                        'FFmpeg conversion returned null, keeping M4A file',
                      );
                    }
                  }
                } catch (e) {
                  _log.w('SAF M4A->FLAC conversion failed: $e');
                } finally {
                  // Clean up temp files
                  try {
                    await File(tempPath).delete();
                  } catch (_) {}
                  if (flacPath != null) {
                    try {
                      await File(flacPath).delete();
                    } catch (_) {}
                  }
                }
              }
            }
          } else {
            // Local file path flow (original)
            if (quality == 'HIGH') {
              final tidalHighFormat = settings.tidalHighFormat;
              _log.i(
                'Tidal HIGH quality download, converting M4A to $tidalHighFormat...',
              );

              try {
                updateItemStatus(
                  item.id,
                  DownloadStatus.downloading,
                  progress: 0.95,
                );

                final format = tidalHighFormat.startsWith('opus')
                    ? 'opus'
                    : 'mp3';
                final convertedPath = await FFmpegService.convertM4aToLossy(
                  currentFilePath,
                  format: format,
                  bitrate: tidalHighFormat,
                  deleteOriginal: true,
                );

                if (convertedPath != null) {
                  filePath = convertedPath;
                  final bitrateDisplay = tidalHighFormat.contains('_')
                      ? '${tidalHighFormat.split('_').last}kbps'
                      : '320kbps';
                  actualQuality = '${format.toUpperCase()} $bitrateDisplay';
                  _log.i(
                    'Successfully converted M4A to $format: $convertedPath',
                  );

                  _log.i('Embedding metadata to $format...');
                  updateItemStatus(
                    item.id,
                    DownloadStatus.downloading,
                    progress: 0.99,
                  );

                  final backendGenre = result['genre'] as String?;
                  final backendLabel = result['label'] as String?;
                  final backendCopyright = result['copyright'] as String?;

                  if (format == 'mp3') {
                    await _embedMetadataToMp3(
                      convertedPath,
                      trackToDownload,
                      genre: backendGenre ?? genre,
                      label: backendLabel ?? label,
                      copyright: backendCopyright,
                    );
                  } else {
                    await _embedMetadataToOpus(
                      convertedPath,
                      trackToDownload,
                      genre: backendGenre ?? genre,
                      label: backendLabel ?? label,
                      copyright: backendCopyright,
                    );
                  }
                  _log.d('Metadata embedded successfully');
                } else {
                  _log.w('M4A to $format conversion failed, keeping M4A file');
                  actualQuality = 'AAC 320kbps';
                }
              } catch (e) {
                _log.w('M4A conversion process failed: $e, keeping M4A file');
                actualQuality = 'AAC 320kbps';
              }
            } else {
              _log.d(
                'M4A file detected (Hi-Res DASH stream), attempting conversion to FLAC...',
              );

              try {
                final file = File(currentFilePath);
                if (!await file.exists()) {
                  _log.e('File does not exist at path: $filePath');
                } else {
                  final length = await file.length();
                  _log.i('File size before conversion: ${length / 1024} KB');

                  if (length < 1024) {
                    _log.w(
                      'File is too small (<1KB), skipping conversion. Download might be corrupt.',
                    );
                  } else {
                    updateItemStatus(
                      item.id,
                      DownloadStatus.downloading,
                      progress: 0.95,
                    );
                    final flacPath = await FFmpegService.convertM4aToFlac(
                      currentFilePath,
                    );

                    if (flacPath != null) {
                      filePath = flacPath;
                      _log.d('Converted to FLAC: $flacPath');

                      _log.d(
                        'Embedding metadata and cover to converted FLAC...',
                      );
                      try {
                        final finalTrack = _buildTrackForMetadataEmbedding(
                          trackToDownload,
                          result,
                          normalizedAlbumArtist,
                        );

                        final backendGenre = result['genre'] as String?;
                        final backendLabel = result['label'] as String?;
                        final backendCopyright = result['copyright'] as String?;

                        if (backendGenre != null ||
                            backendLabel != null ||
                            backendCopyright != null) {
                          _log.d(
                            'Extended metadata from backend - Genre: $backendGenre, Label: $backendLabel, Copyright: $backendCopyright',
                          );
                        }

                        await _embedMetadataAndCover(
                          flacPath,
                          finalTrack,
                          genre: backendGenre ?? genre,
                          label: backendLabel ?? label,
                          copyright: backendCopyright,
                        );
                        _log.d('Metadata and cover embedded successfully');
                      } catch (e) {
                        _log.w('Warning: Failed to embed metadata/cover: $e');
                      }
                    } else {
                      _log.w(
                        'FFmpeg conversion returned null, keeping M4A file',
                      );
                    }
                  }
                }
              } catch (e) {
                _log.w(
                  'FFmpeg conversion process failed: $e, keeping M4A file',
                );
              }
            }
          }
        } else if (isContentUriPath &&
            effectiveSafMode &&
            isFlacFile &&
            !wasExisting) {
          final currentFilePath = filePath;
          _log.d(
            'SAF FLAC detected, embedding metadata and cover via temp file...',
          );
          final tempPath = await _copySafToTemp(currentFilePath);
          if (tempPath != null) {
            try {
              updateItemStatus(
                item.id,
                DownloadStatus.downloading,
                progress: 0.99,
              );

              final finalTrack = _buildTrackForMetadataEmbedding(
                trackToDownload,
                result,
                normalizedAlbumArtist,
              );
              final backendGenre = result['genre'] as String?;
              final backendLabel = result['label'] as String?;
              final backendCopyright = result['copyright'] as String?;

              await _embedMetadataAndCover(
                tempPath,
                finalTrack,
                genre: backendGenre ?? genre,
                label: backendLabel ?? label,
                copyright: backendCopyright,
              );

              final newFileName = '${safBaseName ?? 'track'}.flac';
              final newUri = await _writeTempToSaf(
                treeUri: settings.downloadTreeUri,
                relativeDir: effectiveOutputDir,
                fileName: newFileName,
                mimeType: _mimeTypeForExt('.flac'),
                srcPath: tempPath,
              );

              if (newUri != null) {
                if (newUri != currentFilePath) {
                  await _deleteSafFile(currentFilePath);
                }
                filePath = newUri;
                finalSafFileName = newFileName;
                _log.d('SAF FLAC metadata embedding completed');
              } else {
                _log.w('Failed to write metadata-updated FLAC back to SAF');
              }
            } catch (e) {
              _log.w('SAF FLAC metadata embedding failed: $e');
            } finally {
              try {
                await File(tempPath).delete();
              } catch (_) {}
            }
          }
        } else if (!isContentUriPath &&
            !effectiveSafMode &&
            isFlacFile &&
            !wasExisting &&
            actualService == 'amazon' &&
            decryptionKey.isNotEmpty) {
          _log.d(
            'Local FLAC after Amazon decrypt detected, embedding metadata and cover...',
          );
          try {
            updateItemStatus(
              item.id,
              DownloadStatus.downloading,
              progress: 0.99,
            );

            final finalTrack = _buildTrackForMetadataEmbedding(
              trackToDownload,
              result,
              normalizedAlbumArtist,
            );
            final backendGenre = result['genre'] as String?;
            final backendLabel = result['label'] as String?;
            final backendCopyright = result['copyright'] as String?;

            await _embedMetadataAndCover(
              filePath,
              finalTrack,
              genre: backendGenre ?? genre,
              label: backendLabel ?? label,
              copyright: backendCopyright,
            );
            _log.d('Local FLAC metadata embedding completed');
          } catch (e) {
            _log.w('Local FLAC metadata embedding failed: $e');
          }
        }

        // YouTube downloads: embed metadata to raw Opus/MP3 files from Cobalt
        if (!wasExisting && item.service == 'youtube' && filePath != null) {
          final isOpusFile = filePath.endsWith('.opus');
          final isMp3File = filePath.endsWith('.mp3');

          if (isOpusFile || isMp3File) {
            _log.i(
              'YouTube download: embedding metadata to ${isOpusFile ? 'Opus' : 'MP3'} file',
            );
            updateItemStatus(
              item.id,
              DownloadStatus.downloading,
              progress: 0.95,
            );

            final finalTrack = _buildTrackForMetadataEmbedding(
              trackToDownload,
              result,
              normalizedAlbumArtist,
            );
            final backendGenre = result['genre'] as String?;
            final backendLabel = result['label'] as String?;
            final backendCopyright = result['copyright'] as String?;

            final isContentUriPath = isContentUri(filePath);
            if (isContentUriPath && effectiveSafMode) {
              // SAF mode: copy to temp, embed, write back
              final tempPath = await _copySafToTemp(filePath);
              if (tempPath != null) {
                try {
                  if (isMp3File) {
                    await _embedMetadataToMp3(
                      tempPath,
                      finalTrack,
                      genre: backendGenre ?? genre,
                      label: backendLabel ?? label,
                      copyright: backendCopyright,
                    );
                  } else {
                    await _embedMetadataToOpus(
                      tempPath,
                      finalTrack,
                      genre: backendGenre ?? genre,
                      label: backendLabel ?? label,
                      copyright: backendCopyright,
                    );
                  }
                  // Write back to SAF
                  final ext = isMp3File ? '.mp3' : '.opus';
                  final newFileName = '${safBaseName ?? 'track'}$ext';
                  final newUri = await _writeTempToSaf(
                    treeUri: settings.downloadTreeUri,
                    relativeDir: effectiveOutputDir,
                    fileName: newFileName,
                    mimeType: _mimeTypeForExt(ext),
                    srcPath: tempPath,
                  );
                  if (newUri != null) {
                    if (newUri != filePath) {
                      await _deleteSafFile(filePath);
                    }
                    filePath = newUri;
                    finalSafFileName = newFileName;
                    _log.d('YouTube SAF metadata embedding completed');
                  } else {
                    _log.w('Failed to write metadata-updated file back to SAF');
                  }
                } catch (e) {
                  _log.w('YouTube SAF metadata embedding failed: $e');
                } finally {
                  try {
                    await File(tempPath).delete();
                  } catch (_) {}
                }
              }
            } else {
              // Non-SAF mode: embed directly
              try {
                if (isMp3File) {
                  await _embedMetadataToMp3(
                    filePath,
                    finalTrack,
                    genre: backendGenre ?? genre,
                    label: backendLabel ?? label,
                    copyright: backendCopyright,
                  );
                } else {
                  await _embedMetadataToOpus(
                    filePath,
                    finalTrack,
                    genre: backendGenre ?? genre,
                    label: backendLabel ?? label,
                    copyright: backendCopyright,
                  );
                }
                _log.d('YouTube metadata embedding completed');
              } catch (e) {
                _log.w('YouTube metadata embedding failed: $e');
              }
            }
          }
        }

        final itemAfterDownload = state.items.firstWhere(
          (i) => i.id == item.id,
          orElse: () => item,
        );
        if (itemAfterDownload.status == DownloadStatus.skipped) {
          _log.i('Download was cancelled during finalization, cleaning up');
          if (filePath != null) {
            await deleteFile(filePath);
            _log.d('Deleted cancelled download file: $filePath');
          }
          return;
        }

        updateItemStatus(
          item.id,
          DownloadStatus.completed,
          progress: 1.0,
          filePath: filePath,
        );

        final lyricsMode = settings.lyricsMode;
        final shouldSaveExternalLrc =
            settings.embedLyrics &&
            (lyricsMode == 'external' || lyricsMode == 'both');
        if (shouldSaveExternalLrc &&
            effectiveSafMode &&
            filePath != null &&
            isContentUri(filePath)) {
          String? lrcContent = result['lyrics_lrc'] as String?;
          if (lrcContent == null || lrcContent.isEmpty) {
            try {
              lrcContent = await PlatformBridge.getLyricsLRC(
                trackToDownload.id,
                trackToDownload.name,
                trackToDownload.artistName,
                durationMs: trackToDownload.duration * 1000,
              );
            } catch (e) {
              _log.w('Failed to fetch lyrics for external LRC: $e');
            }
          }

          if (lrcContent != null && lrcContent.isNotEmpty) {
            final baseName = finalSafFileName != null
                ? finalSafFileName.replaceFirst(RegExp(r'\.[^.]+$'), '')
                : safBaseName ??
                      await PlatformBridge.sanitizeFilename(
                        '${trackToDownload.artistName} - ${trackToDownload.name}',
                      );
            await _writeLrcToSaf(
              treeUri: settings.downloadTreeUri,
              relativeDir: effectiveOutputDir,
              baseName: baseName,
              lrcContent: lrcContent,
            );
          }
        }

        if (filePath != null) {
          await _runPostProcessingHooks(filePath, trackToDownload);
        }

        _completedInSession++;

        final historyNotifier = ref.read(downloadHistoryProvider.notifier);
        final existingInHistory =
            historyNotifier.getBySpotifyId(trackToDownload.id) ??
            (trackToDownload.isrc != null
                ? historyNotifier.getByIsrc(trackToDownload.isrc!)
                : null);

        if (wasExisting && existingInHistory != null) {
          _log.i('Track already in library, skipping history update');
          await _notificationService.showDownloadComplete(
            trackName: item.track.name,
            artistName: item.track.artistName,
            completedCount: _completedInSession,
            totalCount: _totalQueuedAtStart,
            alreadyInLibrary: true,
          );
          removeItem(item.id);
          return;
        }

        await _notificationService.showDownloadComplete(
          trackName: item.track.name,
          artistName: item.track.artistName,
          completedCount: _completedInSession,
          totalCount: _totalQueuedAtStart,
          alreadyInLibrary: wasExisting,
        );

        if (filePath != null) {
          final backendTitle = result['title'] as String?;
          final backendArtist = result['artist'] as String?;
          final backendAlbum = result['album'] as String?;
          final backendYear = result['release_date'] as String?;
          final backendTrackNum = result['track_number'] as int?;
          final backendDiscNum = result['disc_number'] as int?;
          final backendBitDepth = result['actual_bit_depth'] as int?;
          final backendSampleRate = result['actual_sample_rate'] as int?;
          final backendISRC = result['isrc'] as String?;
          final backendGenre = result['genre'] as String?;
          final backendLabel = result['label'] as String?;
          final backendCopyright = result['copyright'] as String?;

          _log.d('Saving to history - coverUrl: ${trackToDownload.coverUrl}');

          final historyAlbumArtist =
              (normalizedAlbumArtist != null &&
                  normalizedAlbumArtist != trackToDownload.artistName)
              ? normalizedAlbumArtist
              : null;

          final isMp3 = filePath.endsWith('.mp3');
          final historyBitDepth = isMp3 ? null : backendBitDepth;
          final historySampleRate = isMp3 ? null : backendSampleRate;

          ref
              .read(downloadHistoryProvider.notifier)
              .addToHistory(
                DownloadHistoryItem(
                  id: item.id,
                  trackName: (backendTitle != null && backendTitle.isNotEmpty)
                      ? backendTitle
                      : trackToDownload.name,
                  artistName:
                      (backendArtist != null && backendArtist.isNotEmpty)
                      ? backendArtist
                      : trackToDownload.artistName,
                  albumName: (backendAlbum != null && backendAlbum.isNotEmpty)
                      ? backendAlbum
                      : trackToDownload.albumName,
                  albumArtist: historyAlbumArtist,
                  coverUrl: trackToDownload.coverUrl,
                  filePath: filePath,
                  storageMode: effectiveSafMode ? 'saf' : 'app',
                  downloadTreeUri: effectiveSafMode
                      ? settings.downloadTreeUri
                      : null,
                  safRelativeDir: effectiveSafMode ? effectiveOutputDir : null,
                  safFileName: effectiveSafMode
                      ? (finalSafFileName ?? safFileName)
                      : null,
                  safRepaired: false,
                  service: result['service'] as String? ?? item.service,
                  downloadedAt: DateTime.now(),
                  isrc: (backendISRC != null && backendISRC.isNotEmpty)
                      ? backendISRC
                      : trackToDownload.isrc,
                  spotifyId: trackToDownload.id,
                  trackNumber: (backendTrackNum != null && backendTrackNum > 0)
                      ? backendTrackNum
                      : trackToDownload.trackNumber,
                  discNumber: (backendDiscNum != null && backendDiscNum > 0)
                      ? backendDiscNum
                      : trackToDownload.discNumber,
                  duration: trackToDownload.duration,
                  releaseDate: (backendYear != null && backendYear.isNotEmpty)
                      ? backendYear
                      : trackToDownload.releaseDate,
                  quality: actualQuality,
                  bitDepth: historyBitDepth,
                  sampleRate: historySampleRate,
                  genre: backendGenre,
                  label: backendLabel,
                  copyright: backendCopyright,
                ),
              );

          removeItem(item.id);
        }
      } else {
        final itemAfterFailure = state.items.firstWhere(
          (i) => i.id == item.id,
          orElse: () => item,
        );
        if (itemAfterFailure.status == DownloadStatus.skipped) {
          _log.i('Download was cancelled, skipping error handling');
          return;
        }

        final errorMsg = result['error'] as String? ?? 'Download failed';
        final errorTypeStr = result['error_type'] as String? ?? 'unknown';
        if (errorTypeStr == 'cancelled') {
          _log.i('Download was cancelled by backend, skipping error handling');
          updateItemStatus(item.id, DownloadStatus.skipped);
          return;
        }

        DownloadErrorType errorType;
        switch (errorTypeStr) {
          case 'not_found':
            errorType = DownloadErrorType.notFound;
            break;
          case 'rate_limit':
            errorType = DownloadErrorType.rateLimit;
            break;
          case 'network':
            errorType = DownloadErrorType.network;
            break;
          case 'permission':
            errorType = DownloadErrorType.permission;
            break;
          default:
            errorType = DownloadErrorType.unknown;
        }

        _log.e('Download failed: $errorMsg (type: $errorTypeStr)');
        updateItemStatus(
          item.id,
          DownloadStatus.failed,
          error: errorMsg,
          errorType: errorType,
        );
        _failedInSession++;

        // Immediately cleanup connections after failure to prevent
        // poisoned connection pool from affecting subsequent downloads
        try {
          await PlatformBridge.cleanupConnections();
        } catch (e) {
          _log.e('Post-failure connection cleanup failed: $e');
        }
      }

      _downloadCount++;
      if (_downloadCount % _cleanupInterval == 0) {
        _log.d(
          'Cleaning up idle connections (after $_downloadCount downloads)...',
        );
        try {
          await PlatformBridge.cleanupConnections();
        } catch (e) {
          _log.e('Connection cleanup failed: $e');
        }
      }
    } catch (e, stackTrace) {
      final itemAfterError = state.items.firstWhere(
        (i) => i.id == item.id,
        orElse: () => item,
      );
      if (itemAfterError.status == DownloadStatus.skipped) {
        _log.i('Download was cancelled, skipping error handling');
        return;
      }

      _log.e('Exception: $e', e, stackTrace);

      String errorMsg = e.toString();
      DownloadErrorType errorType = DownloadErrorType.unknown;

      if (errorMsg.contains('could not find Deezer equivalent') ||
          errorMsg.contains('track not found on Deezer')) {
        errorMsg = 'Track not found on Deezer (Metadata Unavailable)';
        errorType = DownloadErrorType.notFound;
      }

      updateItemStatus(
        item.id,
        DownloadStatus.failed,
        error: errorMsg,
        errorType: errorType,
      );
      _failedInSession++;

      // Immediately cleanup connections after exception
      try {
        await PlatformBridge.cleanupConnections();
      } catch (cleanupErr) {
        _log.e('Post-exception connection cleanup failed: $cleanupErr');
      }
    }
  }
}

final downloadQueueProvider =
    NotifierProvider<DownloadQueueNotifier, DownloadQueueState>(
      DownloadQueueNotifier.new,
    );

class DownloadQueueLookup {
  final Map<String, DownloadItem> byTrackId;

  DownloadQueueLookup._(this.byTrackId);

  factory DownloadQueueLookup.fromItems(List<DownloadItem> items) {
    final map = <String, DownloadItem>{};
    for (final item in items) {
      map.putIfAbsent(item.track.id, () => item);
    }
    return DownloadQueueLookup._(map);
  }
}

final downloadQueueLookupProvider = Provider<DownloadQueueLookup>((ref) {
  final items = ref.watch(downloadQueueProvider.select((s) => s.items));
  return DownloadQueueLookup.fromItems(items);
});
