import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/models/settings.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
import 'package:spotiflac_android/providers/extension_provider.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/services/ffmpeg_service.dart';
import 'package:spotiflac_android/services/notification_service.dart';
import 'package:spotiflac_android/services/history_database.dart';
import 'package:spotiflac_android/utils/logger.dart';

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
          .where((item) => item.spotifyId != null && item.spotifyId!.isNotEmpty)
          .map((item) => MapEntry(item.spotifyId!, item)),
      ),
      _byIsrc = Map.fromEntries(
        items
          .where((item) => item.isrc != null && item.isrc!.isNotEmpty)
          .map((item) => MapEntry(item.isrc!, item)),
      );

  /// O(1) check if spotify_id exists
  bool isDownloaded(String spotifyId) =>
      _downloadedSpotifyIds.contains(spotifyId);
  
  /// O(1) lookup by spotify_id
  DownloadHistoryItem? getBySpotifyId(String spotifyId) =>
      _bySpotifyId[spotifyId];
  
  /// O(1) lookup by ISRC
  DownloadHistoryItem? getByIsrc(String isrc) =>
      _byIsrc[isrc];

  DownloadHistoryState copyWith({List<DownloadHistoryItem>? items}) {
    return DownloadHistoryState(items: items ?? this.items);
  }
}

class DownloadHistoryNotifier extends Notifier<DownloadHistoryState> {
  final HistoryDatabase _db = HistoryDatabase.instance;
  bool _isLoaded = false;

  @override
  DownloadHistoryState build() {
    _loadFromDatabaseSync();
    return DownloadHistoryState();
  }

  /// Synchronously schedule load - ensures it runs before any UI renders
  void _loadFromDatabaseSync() {
    if (_isLoaded) return;
    Future.microtask(() async {
      await _loadFromDatabase();
      _isLoaded = true;
    });
  }

  Future<void> _loadFromDatabase() async {
    try {
      final migrated = await _db.migrateFromSharedPreferences();
      if (migrated) {
        _historyLog.i('Migrated history from SharedPreferences to SQLite');
      }
      
      // Migrate iOS paths if container UUID changed after app update
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
    } catch (e, stack) {
      _historyLog.e('Failed to load history from database: $e', e, stack);
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
      final updatedItems = state.items.where((i) => i.id != existing!.id).toList();
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
  
  /// O(1) lookup by ISRC
  DownloadHistoryItem? getByIsrc(String isrc) {
    return state.getByIsrc(isrc);
  }
  
  /// Async version with database lookup (for cases where in-memory might be stale)
  Future<DownloadHistoryItem?> getBySpotifyIdAsync(String spotifyId) async {
    final inMemory = state.getBySpotifyId(spotifyId);
    if (inMemory != null) return inMemory;
    
    final json = await _db.getBySpotifyId(spotifyId);
    if (json == null) return null;
    return DownloadHistoryItem.fromJson(json);
  }

  void clearHistory() {
    state = DownloadHistoryState();
    _db.clearAll().catchError((e) {
      _historyLog.e('Failed to clear database: $e');
    });
  }
  
  /// Get database stats for debugging
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

  const _ProgressUpdate({
    required this.status,
    required this.progress,
    this.speedMBps,
  });
}

class DownloadQueueNotifier extends Notifier<DownloadQueueState> {
  Timer? _progressTimer;
  int _downloadCount = 0;
  static const _cleanupInterval = 50;
  static const _queueStorageKey = 'download_queue';
  final NotificationService _notificationService = NotificationService();
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  int _totalQueuedAtStart = 0;
  int _completedInSession = 0;
  int _failedInSession = 0;
  bool _isLoaded = false;
  final Set<String> _ensuredDirs = {};

  @override
  DownloadQueueState build() {
    ref.onDispose(() {
      _progressTimer?.cancel();
      _progressTimer = null;
    });

    Future.microtask(() async {
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
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      try {
        final allProgress = await PlatformBridge.getAllDownloadProgress();
        final items = allProgress['items'] as Map<String, dynamic>? ?? {};
        final currentItems = state.items;
        final itemsById = <String, DownloadItem>{};
        final itemIndexById = <String, int>{};
        for (int i = 0; i < currentItems.length; i++) {
          final item = currentItems[i];
          itemsById[item.id] = item;
          itemIndexById[item.id] = i;
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
            );
            if (current.status != next.status ||
                current.progress != next.progress ||
                current.speedMBps != next.speedMBps) {
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

          final downloadingItems = state.items
              .where((i) => i.status == DownloadStatus.downloading)
              .toList();
          if (downloadingItems.isNotEmpty) {
            final trackName = downloadingItems.length == 1
                ? downloadingItems.first.track.name
                : '${downloadingItems.length} downloads';
            final artistName = downloadingItems.length == 1
                ? downloadingItems.first.track.artistName
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
              PlatformBridge.updateDownloadServiceProgress(
                trackName: downloadingItems.first.track.name,
                artistName: downloadingItems.first.track.artistName,
                progress: notifProgress,
                total: notifTotal > 0 ? notifTotal : 1,
                queueCount: state.queuedCount,
              ).catchError((_) {});
            }
          }
        }
      } catch (_) {}
    });
  }

  void _stopProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = null;
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

  Future<String> _buildOutputDir(Track track, String folderOrganization, {bool separateSingles = false, String albumFolderStructure = 'artist_album'}) async {
    String baseDir = state.outputDir;
    final albumArtist = _normalizeOptionalString(track.albumArtist) ?? track.artistName;

    if (separateSingles) {
      final isSingle = track.isSingle;
      final artistName = _sanitizeFolderName(albumArtist);
      
      // New option: Singles folder inside Artist folder
      if (albumFolderStructure == 'artist_album_singles') {
        if (isSingle) {
          final singlesPath = '$baseDir${Platform.pathSeparator}$artistName${Platform.pathSeparator}Singles';
          await _ensureDirExists(singlesPath, label: 'Artist Singles folder');
          return singlesPath;
        } else {
          final albumName = _sanitizeFolderName(track.albumName);
          final albumPath = '$baseDir${Platform.pathSeparator}$artistName${Platform.pathSeparator}$albumName';
          await _ensureDirExists(albumPath, label: 'Artist Album folder');
          return albumPath;
        }
      }
      
      // Existing behavior: Separate Albums/ and Singles/ at root
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
            albumPath = '$baseDir${Platform.pathSeparator}Albums${Platform.pathSeparator}$albumName';
            break;
          case 'artist_year_album':
            final yearAlbum = year != null ? '[$year] $albumName' : albumName;
            albumPath = '$baseDir${Platform.pathSeparator}Albums${Platform.pathSeparator}$artistName${Platform.pathSeparator}$yearAlbum';
            break;
          case 'year_album':
            final yearAlbum = year != null ? '[$year] $albumName' : albumName;
            albumPath = '$baseDir${Platform.pathSeparator}Albums${Platform.pathSeparator}$yearAlbum';
            break;
          default:
            albumPath = '$baseDir${Platform.pathSeparator}Albums${Platform.pathSeparator}$artistName${Platform.pathSeparator}$albumName';
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
        final artistName = _sanitizeFolderName(albumArtist);
        subPath = artistName;
        break;
      case 'album':
        final albumName = _sanitizeFolderName(track.albumName);
        subPath = albumName;
        break;
      case 'artist_album':
        final artistName = _sanitizeFolderName(albumArtist);
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

  /// Extract year from release date (format: "2005-06-13" or "2005")
  String? _extractYear(String? releaseDate) {
    if (releaseDate == null || releaseDate.isEmpty) return null;
    final match = _yearRegex.firstMatch(releaseDate);
    return match?.group(1);
  }

  void updateSettings(AppSettings settings) {
    state = state.copyWith(
      outputDir: settings.downloadDirectory.isNotEmpty
          ? settings.downloadDirectory
          : state.outputDir,
      filenameFormat: settings.filenameFormat,
      audioQuality: settings.audioQuality,
      autoFallback: settings.autoFallback,
      concurrentDownloads: settings.concurrentDownloads,
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
        'album_artist': _normalizeOptionalString(track.albumArtist) ?? track.artistName,
        'track_number': track.trackNumber ?? 1,
        'disc_number': track.discNumber ?? 1,
        'isrc': track.isrc ?? '',
        'release_date': track.releaseDate ?? '',
        'duration_ms': track.duration * 1000,
        'cover_url': track.coverUrl ?? '',
      };
      
      final result = await PlatformBridge.runPostProcessing(filePath, metadata: metadata);
      
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

  /// Same logic as Go backend cover.go
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

      final albumArtist = _normalizeOptionalString(track.albumArtist) ??
          track.artistName;
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

        // Skip instrumental tracks (no lyrics to embed)
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
          _log.w('Failed to download cover for MP3: HTTP ${response.statusCode}');
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

      final albumArtist = _normalizeOptionalString(track.albumArtist) ??
          track.artistName;
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

      if (settings.embedLyrics) {
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
            metadata['LYRICS'] = lrcContent;
            metadata['UNSYNCEDLYRICS'] = lrcContent;
            _log.d('Lyrics fetched for MP3 embedding (${lrcContent.length} chars)');
          }
        } catch (e) {
          _log.w('Failed to fetch lyrics for MP3 embedding: $e');
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

  Future<void> _processQueue() async {
    if (state.isProcessing) return;

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

    if (state.outputDir.isEmpty) {
      _log.d('Output dir empty, initializing...');
      await _initOutputDir();
    }

    if (state.outputDir.isEmpty) {
      _log.d('Using fallback directory...');
      final dir = await getApplicationDocumentsDirectory();
      final musicDir = Directory('${dir.path}/SpotiFLAC');
      if (!await musicDir.exists()) {
        await musicDir.create(recursive: true);
      }
      state = state.copyWith(outputDir: musicDir.path);
    }

    _log.d('Output directory: ${state.outputDir}');
    _log.d('Concurrent downloads: ${state.concurrentDownloads}');

    if (state.concurrentDownloads > 1) {
      await _processQueueParallel();
    } else {
      await _processQueueSequential();
    }

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

  Future<void> _processQueueSequential() async {
    _startMultiProgressPolling();

    while (true) {
      if (state.isPaused) {
        _log.d('Queue is paused, waiting...');
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      final currentItems = state.items;
      final nextIndex = currentItems.indexWhere(
        (item) => item.status == DownloadStatus.queued,
      );
      if (nextIndex == -1) {
        _log.d(
          'No more items to process (checked ${currentItems.length} items)',
        );
        break;
      }

      final nextItem = currentItems[nextIndex];
      _log.d(
        'Processing next item: ${nextItem.track.name} (id: ${nextItem.id})',
      );
      await _downloadSingleItem(nextItem);

      PlatformBridge.clearItemProgress(nextItem.id).catchError((_) {});
    }

    _stopProgressPolling();
  }

  Future<void> _processQueueParallel() async {
    final maxConcurrent = state.concurrentDownloads;
    final activeDownloads = <String, Future<void>>{};


    _startMultiProgressPolling();

    while (true) {
      if (state.isPaused) {
        _log.d('Queue is paused, waiting for active downloads...');
        if (activeDownloads.isNotEmpty) {
          await Future.any(activeDownloads.values);
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
        }
        continue;
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
        await Future.any(activeDownloads.values);
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
                albumType: (data['album_type'] as String?) ?? trackToDownload.albumType,
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

      final normalizedAlbumArtist =
          _normalizeOptionalString(trackToDownload.albumArtist);

      final outputDir = await _buildOutputDir(
        trackToDownload,
        settings.folderOrganization,
        separateSingles: settings.separateSingles,
        albumFolderStructure: settings.albumFolderStructure,
      );

      final quality = item.qualityOverride ?? state.audioQuality;

// Fetch extended metadata (genre, label) from Deezer if available
      String? genre;
      String? label;
      
      String? deezerTrackId = trackToDownload.deezerId;
      if (deezerTrackId == null && trackToDownload.id.startsWith('deezer:')) {
        deezerTrackId = trackToDownload.id.split(':')[1];
      }
      if (deezerTrackId == null && trackToDownload.availability?.deezerId != null) {
        deezerTrackId = trackToDownload.availability!.deezerId;
      }
      
      if (deezerTrackId == null && trackToDownload.isrc != null && trackToDownload.isrc!.isNotEmpty) {
        try {
          _log.d('No Deezer ID, searching by ISRC: ${trackToDownload.isrc}');
          final deezerResult = await PlatformBridge.searchDeezerByISRC(trackToDownload.isrc!);
          if (deezerResult['success'] == true && deezerResult['track_id'] != null) {
            deezerTrackId = deezerResult['track_id'].toString();
            _log.d('Found Deezer track ID via ISRC: $deezerTrackId');
          }
        } catch (e) {
          _log.w('Failed to search Deezer by ISRC: $e');
        }
      }
      
      if (deezerTrackId != null && deezerTrackId.isNotEmpty) {
        try {
          final extendedMetadata = await PlatformBridge.getDeezerExtendedMetadata(deezerTrackId);
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
      final hasActiveExtensions = extensionState.extensions.any((e) => e.enabled);
      final useExtensions = settings.useExtensionProviders && hasActiveExtensions;

      if (useExtensions) {
        _log.d('Using extension providers for download');
        _log.d(
          'Quality: $quality${item.qualityOverride != null ? ' (override)' : ''}',
        );
        _log.d('Output dir: $outputDir');
        result = await PlatformBridge.downloadWithExtensions(
          isrc: trackToDownload.isrc ?? '',
          spotifyId: trackToDownload.id,
          trackName: trackToDownload.name,
          artistName: trackToDownload.artistName,
          albumName: trackToDownload.albumName,
          albumArtist: normalizedAlbumArtist,
          coverUrl: trackToDownload.coverUrl,
          outputDir: outputDir,
          filenameFormat: state.filenameFormat,
          quality: quality,
          trackNumber: trackToDownload.trackNumber ?? 1,
          discNumber: trackToDownload.discNumber ?? 1,
          releaseDate: trackToDownload.releaseDate,
          itemId: item.id,
          durationMs: trackToDownload.duration,
          source: trackToDownload.source,
          genre: genre,
          label: label,
          lyricsMode: settings.lyricsMode,
        );
      } else if (state.autoFallback) {
        _log.d('Using auto-fallback mode');
        _log.d(
          'Quality: $quality${item.qualityOverride != null ? ' (override)' : ''}',
        );
        _log.d('Output dir: $outputDir');
        result = await PlatformBridge.downloadWithFallback(
          isrc: trackToDownload.isrc ?? '',
          spotifyId: trackToDownload.id,
          trackName: trackToDownload.name,
          artistName: trackToDownload.artistName,
          albumName: trackToDownload.albumName,
          albumArtist: normalizedAlbumArtist,
          coverUrl: trackToDownload.coverUrl,
          outputDir: outputDir,
          filenameFormat: state.filenameFormat,
          quality: quality,
          trackNumber: trackToDownload.trackNumber ?? 1,
          discNumber: trackToDownload.discNumber ?? 1,
          releaseDate: trackToDownload.releaseDate,
          preferredService: item.service,
          itemId: item.id,
          durationMs: trackToDownload.duration,
          genre: genre,
          label: label,
          lyricsMode: settings.lyricsMode,
        );
      } else {
        result = await PlatformBridge.downloadTrack(
          isrc: trackToDownload.isrc ?? '',
          service: item.service,
          spotifyId: trackToDownload.id,
          trackName: trackToDownload.name,
          artistName: trackToDownload.artistName,
          albumName: trackToDownload.albumName,
          albumArtist: normalizedAlbumArtist,
          coverUrl: trackToDownload.coverUrl,
          outputDir: outputDir,
          filenameFormat: state.filenameFormat,
          quality: quality,
          trackNumber: trackToDownload.trackNumber ?? 1,
          discNumber: trackToDownload.discNumber ?? 1,
          releaseDate: trackToDownload.releaseDate,
          itemId: item.id,
          durationMs: trackToDownload.duration,
        );
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
          try {
            final file = File(filePath);
            if (await file.exists()) {
              await file.delete();
              _log.d('Deleted cancelled download file: $filePath');
            }
          } catch (e) {
            _log.w('Failed to delete cancelled file: $e');
          }
        }
        return;
      }

      if (result['success'] == true) {
        var filePath = result['file_path'] as String?;
        
        final wasExisting = filePath != null && filePath.startsWith('EXISTS:');
        if (wasExisting) {
          filePath = filePath.substring(7); // Remove "EXISTS:" prefix
          _log.i('Using existing file: $filePath');
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

        if (filePath != null && filePath.endsWith('.m4a')) {
          _log.d(
            'M4A file detected (Hi-Res DASH stream), attempting conversion to FLAC...',
          );

          try {
            final file = File(filePath);
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
                final flacPath = await FFmpegService.convertM4aToFlac(filePath);

                if (flacPath != null) {
                  filePath = flacPath;
                  _log.d('Converted to FLAC: $flacPath');

                  _log.d('Embedding metadata and cover to converted FLAC...');
                  try {
                    Track finalTrack = trackToDownload;
                    if (result.containsKey('track_number') ||
                        result.containsKey('release_date')) {
                      _log.d(
                        'Using metadata from backend response for embedding',
                      );
                      final backendTrackNum = result['track_number'] as int?;
                      final backendDiscNum = result['disc_number'] as int?;
                      final backendYear = result['release_date'] as String?;
                      final backendAlbum = result['album'] as String?;

                      _log.d(
                        'Backend metadata - Track: $backendTrackNum, Disc: $backendDiscNum, Year: $backendYear',
                      );

                      final newTrackNumber =
                          (backendTrackNum != null && backendTrackNum > 0)
                          ? backendTrackNum
                          : trackToDownload.trackNumber;
                      final newDiscNumber =
                          (backendDiscNum != null && backendDiscNum > 0)
                          ? backendDiscNum
                          : trackToDownload.discNumber;

                      _log.d(
                        'Final metadata for embedding - Track: $newTrackNumber, Disc: $newDiscNumber',
                      );

                      finalTrack = Track(
                        id: trackToDownload.id,
                        name: trackToDownload.name,
                        artistName: trackToDownload.artistName,
                        albumName: backendAlbum ?? trackToDownload.albumName,
                        albumArtist: normalizedAlbumArtist,
                        coverUrl: trackToDownload.coverUrl,
                        duration: trackToDownload.duration,
                        isrc: trackToDownload.isrc,
                        trackNumber: newTrackNumber,
                        discNumber: newDiscNumber,
                        releaseDate: backendYear ?? trackToDownload.releaseDate,
                        deezerId: trackToDownload.deezerId,
                        availability: trackToDownload.availability,
                        albumType: trackToDownload.albumType,
                        source: trackToDownload.source,
                      );
                    }

                    final backendGenre = result['genre'] as String?;
                    final backendLabel = result['label'] as String?;
                    final backendCopyright = result['copyright'] as String?;
                    
                    if (backendGenre != null || backendLabel != null || backendCopyright != null) {
                      _log.d('Extended metadata from backend - Genre: $backendGenre, Label: $backendLabel, Copyright: $backendCopyright');
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
                  _log.w('FFmpeg conversion returned null, keeping M4A file');
                }
              }
            }
          } catch (e) {
            _log.w('FFmpeg conversion process failed: $e, keeping M4A file');
          }
        }

        final itemAfterDownload = state.items.firstWhere(
          (i) => i.id == item.id,
          orElse: () => item,
        );
        if (itemAfterDownload.status == DownloadStatus.skipped) {
          _log.i('Download was cancelled during finalization, cleaning up');
          if (filePath != null) {
            try {
              final file = File(filePath);
              if (await file.exists()) {
                await file.delete();
                _log.d('Deleted cancelled download file: $filePath');
              }
            } catch (e) {
              _log.w('Failed to delete cancelled file: $e');
            }
          }
          return;
        }

        if (quality == 'MP3' && filePath != null && filePath.endsWith('.flac')) {
          if (wasExisting) {
            _log.i('MP3 requested but existing FLAC found - skipping conversion to preserve original file');
          } else {
            _log.i('MP3 quality selected, converting FLAC to MP3...');
            updateItemStatus(
              item.id,
              DownloadStatus.downloading,
              progress: 0.97,
            );
            
            try {
              final mp3Path = await FFmpegService.convertFlacToMp3(
                filePath,
                bitrate: '320k',
                deleteOriginal: true,
              );
              
              if (mp3Path != null) {
                filePath = mp3Path;
                actualQuality = 'MP3 320kbps';
                _log.i('Successfully converted to MP3: $mp3Path');
                
                _log.i('Embedding metadata to MP3...');
                updateItemStatus(
                  item.id,
                  DownloadStatus.downloading,
                  progress: 0.99,
                );
                
                final mp3BackendGenre = result['genre'] as String?;
                final mp3BackendLabel = result['label'] as String?;
                final mp3BackendCopyright = result['copyright'] as String?;
                
                await _embedMetadataToMp3(
                  mp3Path, 
                  trackToDownload,
                  genre: mp3BackendGenre ?? genre,
                  label: mp3BackendLabel ?? label,
                  copyright: mp3BackendCopyright,
                );
              } else {
                _log.w('MP3 conversion failed, keeping FLAC file');
              }
            } catch (e) {
              _log.e('MP3 conversion error: $e, keeping FLAC file');
            }
          }
        }

        updateItemStatus(
          item.id,
          DownloadStatus.completed,
          progress: 1.0,
          filePath: filePath,
        );

        if (filePath != null) {
          await _runPostProcessingHooks(filePath, trackToDownload);
        }

        _completedInSession++;
        
        await _notificationService.showDownloadComplete(
          trackName: item.track.name,
          artistName: item.track.artistName,
          completedCount: _completedInSession,
          totalCount: _totalQueuedAtStart,
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
                  artistName: (backendArtist != null && backendArtist.isNotEmpty)
                      ? backendArtist
                      : trackToDownload.artistName,
                  albumName: (backendAlbum != null && backendAlbum.isNotEmpty)
                      ? backendAlbum
                      : trackToDownload.albumName,
                  albumArtist: historyAlbumArtist,
                  coverUrl: trackToDownload.coverUrl,
                  filePath: filePath,
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
