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
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('DownloadQueue');
final _historyLog = AppLogger('DownloadHistory');

// Download History Item model
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
  // Additional metadata
  final String? isrc;
  final String? spotifyId;
  final int? trackNumber;
  final int? discNumber;
  final int? duration;
  final String? releaseDate;
  final String? quality;
  // Audio quality info (from file after download)
  final int? bitDepth;
  final int? sampleRate;

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
  };

  factory DownloadHistoryItem.fromJson(Map<String, dynamic> json) =>
      DownloadHistoryItem(
        id: json['id'] as String,
        trackName: json['trackName'] as String,
        artistName: json['artistName'] as String,
        albumName: json['albumName'] as String,
        albumArtist: json['albumArtist'] as String?,
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
      );
}

// Download History State
class DownloadHistoryState {
  final List<DownloadHistoryItem> items;
  final Set<String> _downloadedSpotifyIds; // Cache for O(1) lookup

  DownloadHistoryState({this.items = const []})
    : _downloadedSpotifyIds = items
          .where((item) => item.spotifyId != null && item.spotifyId!.isNotEmpty)
          .map((item) => item.spotifyId!)
          .toSet();

  /// Check if a track has been downloaded (by Spotify ID)
  bool isDownloaded(String spotifyId) =>
      _downloadedSpotifyIds.contains(spotifyId);

  DownloadHistoryState copyWith({List<DownloadHistoryItem>? items}) {
    return DownloadHistoryState(items: items ?? this.items);
  }
}

// Download History Notifier (Riverpod 3.x)
class DownloadHistoryNotifier extends Notifier<DownloadHistoryState> {
  static const _storageKey = 'download_history';
  bool _isLoaded = false;

  @override
  DownloadHistoryState build() {
    // Load history from storage on init
    _loadFromStorageSync();
    return DownloadHistoryState();
  }

  /// Synchronously schedule load - ensures it runs before any UI renders
  void _loadFromStorageSync() {
    if (_isLoaded) return;
    Future.microtask(() async {
      await _loadFromStorage();
      _isLoaded = true;
    });
  }

  Future<void> _loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_storageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        final items = jsonList
            .map((e) => DownloadHistoryItem.fromJson(e as Map<String, dynamic>))
            .toList();
        state = state.copyWith(items: items);
        _historyLog.i('Loaded ${items.length} items from storage');
      } else {
        _historyLog.d('No history found in storage');
      }
    } catch (e) {
      _historyLog.e('Failed to load history: $e');
    }
  }

  Future<void> _saveToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonList = state.items.map((e) => e.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(jsonList));
      _historyLog.d('Saved ${state.items.length} items to storage');
    } catch (e) {
      _historyLog.e('Failed to save history: $e');
    }
  }

  /// Force reload from storage (useful after app restart)
  Future<void> reloadFromStorage() async {
    await _loadFromStorage();
  }

  void addToHistory(DownloadHistoryItem item) {
    state = state.copyWith(items: [item, ...state.items]);
    _saveToStorage();
  }

  void removeFromHistory(String id) {
    state = state.copyWith(
      items: state.items.where((item) => item.id != id).toList(),
    );
    _saveToStorage();
  }

  /// Remove item from history by Spotify ID
  void removeBySpotifyId(String spotifyId) {
    state = state.copyWith(
      items: state.items.where((item) => item.spotifyId != spotifyId).toList(),
    );
    _saveToStorage();
    _historyLog.d('Removed item with spotifyId: $spotifyId');
  }

  /// Get history item by Spotify ID
  DownloadHistoryItem? getBySpotifyId(String spotifyId) {
    return state.items.where((item) => item.spotifyId == spotifyId).firstOrNull;
  }

  void clearHistory() {
    state = DownloadHistoryState();
    _saveToStorage();
  }
}

// Download History Provider
final downloadHistoryProvider =
    NotifierProvider<DownloadHistoryNotifier, DownloadHistoryState>(
      DownloadHistoryNotifier.new,
    );

class DownloadQueueState {
  final List<DownloadItem> items;
  final DownloadItem? currentDownload;
  final bool isProcessing;
  final bool isPaused; // NEW: pause state
  final String outputDir;
  final String filenameFormat;
  final String audioQuality; // LOSSLESS, HI_RES, HI_RES_LOSSLESS
  final bool autoFallback;
  final int concurrentDownloads; // 1 = sequential, max 3

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

// Download Queue Notifier (Riverpod 3.x)
class DownloadQueueNotifier extends Notifier<DownloadQueueState> {
  Timer? _progressTimer;
  int _downloadCount = 0; // Counter for connection cleanup
  static const _cleanupInterval = 50; // Cleanup every 50 downloads
  static const _queueStorageKey =
      'download_queue'; // Storage key for queue persistence
  final NotificationService _notificationService = NotificationService();
  int _totalQueuedAtStart = 0; // Track total items when queue started
  int _completedInSession = 0; // Track completed downloads in current session
  int _failedInSession = 0; // Track failed downloads in current session
  bool _isLoaded = false;

  @override
  DownloadQueueState build() {
    // Cleanup timer when provider is disposed
    ref.onDispose(() {
      _progressTimer?.cancel();
      _progressTimer = null;
    });

    // Initialize output directory and load persisted queue asynchronously
    Future.microtask(() async {
      await _initOutputDir();
      await _loadQueueFromStorage();
    });
    return const DownloadQueueState();
  }

  /// Load persisted queue from storage (for app restart recovery)
  Future<void> _loadQueueFromStorage() async {
    if (_isLoaded) return;
    _isLoaded = true;

    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_queueStorageKey);
      if (jsonStr != null && jsonStr.isNotEmpty) {
        final List<dynamic> jsonList = jsonDecode(jsonStr);
        final items = jsonList
            .map((e) => DownloadItem.fromJson(e as Map<String, dynamic>))
            .toList();

        // Reset downloading items to queued (they were interrupted)
        final restoredItems = items.map((item) {
          if (item.status == DownloadStatus.downloading) {
            return item.copyWith(status: DownloadStatus.queued, progress: 0);
          }
          return item;
        }).toList();

        // Only restore queued/downloading items (not completed/failed/skipped)
        final pendingItems = restoredItems
            .where((item) => item.status == DownloadStatus.queued)
            .toList();

        if (pendingItems.isNotEmpty) {
          state = state.copyWith(items: pendingItems);
          _log.i('Restored ${pendingItems.length} pending items from storage');

          // Auto-resume queue processing
          Future.microtask(() => _processQueue());
        } else {
          _log.d('No pending items to restore');
          // Clear storage since nothing to restore
          await prefs.remove(_queueStorageKey);
        }
      } else {
        _log.d('No queue found in storage');
      }
    } catch (e) {
      _log.e('Failed to load queue from storage: $e');
    }
  }

  /// Save current queue to storage (only pending items)
  Future<void> _saveQueueToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Only persist queued and downloading items
      final pendingItems = state.items
          .where(
            (item) =>
                item.status == DownloadStatus.queued ||
                item.status == DownloadStatus.downloading,
          )
          .toList();

      if (pendingItems.isEmpty) {
        // Clear storage if no pending items
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

  /// Start multi-progress polling for all downloads (sequential and parallel)
  void _startMultiProgressPolling() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (
      timer,
    ) async {
      try {
        final allProgress = await PlatformBridge.getAllDownloadProgress();
        final items = allProgress['items'] as Map<String, dynamic>? ?? {};

        bool hasFinalizingItem = false;
        String? finalizingTrackName;
        String? finalizingArtistName;

        for (final entry in items.entries) {
          final itemId = entry.key;
          final itemProgress = entry.value as Map<String, dynamic>;
          final bytesReceived = itemProgress['bytes_received'] as int? ?? 0;
          final bytesTotal = itemProgress['bytes_total'] as int? ?? 0;
          final speedMBps =
              (itemProgress['speed_mbps'] as num?)?.toDouble() ?? 0.0;
          final isDownloading =
              itemProgress['is_downloading'] as bool? ?? false;
          final status = itemProgress['status'] as String? ?? 'downloading';

          // Check if status is "finalizing" (embedding metadata)
          // Only trust finalizing status if bytesTotal > 0 (download actually happened)
          if (status == 'finalizing' && bytesTotal > 0) {
            updateItemStatus(itemId, DownloadStatus.finalizing, progress: 1.0);

            // Track finalizing item for notification
            final currentItem = state.items
                .where((i) => i.id == itemId)
                .firstOrNull;
            if (currentItem != null) {
              hasFinalizingItem = true;
              finalizingTrackName = currentItem.track.name;
              finalizingArtistName = currentItem.track.artistName;
            }
            continue;
          }

          // Use progress from backend if available (handles both explicit progress and byte-based)
          final progressFromBackend =
              (itemProgress['progress'] as num?)?.toDouble() ?? 0.0;

          if (isDownloading) {
            double percentage = 0.0;
            if (bytesTotal > 0) {
              // Calculate from bytes if available for precision
              percentage = bytesReceived / bytesTotal;
            } else {
              // Fallback to backend-reported progress (e.g. for DASH segments)
              percentage = progressFromBackend;
            }

            updateProgress(itemId, percentage, speedMBps: speedMBps);

            // Log progress for each item with speed
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

        // Show finalizing notification if any item is finalizing (takes priority)
        if (hasFinalizingItem && finalizingTrackName != null) {
          _notificationService.showDownloadFinalizing(
            trackName: finalizingTrackName,
            artistName: finalizingArtistName ?? '',
          );
          return; // Don't show download progress notification
        }

        // Update notification with active downloads
        if (items.isNotEmpty) {
          final firstEntry = items.entries.first;
          final firstProgress = firstEntry.value as Map<String, dynamic>;
          final bytesReceived = firstProgress['bytes_received'] as int? ?? 0;
          final bytesTotal = firstProgress['bytes_total'] as int? ?? 0;

          // Find downloading items (not finalizing)
          final downloadingItems = state.items
              .where((i) => i.status == DownloadStatus.downloading)
              .toList();
          if (downloadingItems.isNotEmpty) {
            // Show single track name if only 1 download, otherwise show count
            final trackName = downloadingItems.length == 1
                ? downloadingItems.first.track.name
                : '${downloadingItems.length} downloads';
            final artistName = downloadingItems.length == 1
                ? downloadingItems.first.track.artistName
                : 'Downloading...';

            // Calculate notification progress values
            int notifProgress = bytesReceived;
            int notifTotal = bytesTotal;

            if (bytesTotal <= 0) {
              // Fallback to percentage for DASH/unknown size
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

            // Update foreground service notification (Android)
            if (Platform.isAndroid) {
              PlatformBridge.updateDownloadServiceProgress(
                trackName: downloadingItems.first.track.name,
                artistName: downloadingItems.first.track.artistName,
                progress: notifProgress,
                total: notifTotal > 0 ? notifTotal : 1,
                queueCount: state.queuedCount,
              ).catchError((_) {}); // Ignore errors
            }
          }
        }
      } catch (e) {
        // Ignore polling errors
      }
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
          // iOS: Use Documents directory (accessible via Files app)
          final dir = await getApplicationDocumentsDirectory();
          final musicDir = Directory('${dir.path}/SpotiFLAC');
          if (!await musicDir.exists()) {
            await musicDir.create(recursive: true);
          }
          state = state.copyWith(outputDir: musicDir.path);
        } else {
          // Android: Use external storage Music folder
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
            // Fallback to documents directory
            final docDir = await getApplicationDocumentsDirectory();
            final musicDir = Directory('${docDir.path}/SpotiFLAC');
            if (!await musicDir.exists()) {
              await musicDir.create(recursive: true);
            }
            state = state.copyWith(outputDir: musicDir.path);
          }
        }
      } catch (e) {
        // Fallback for any platform
        final dir = await getApplicationDocumentsDirectory();
        final musicDir = Directory('${dir.path}/SpotiFLAC');
        if (!await musicDir.exists()) {
          await musicDir.create(recursive: true);
        }
        state = state.copyWith(outputDir: musicDir.path);
      }
    }
  }

  void setOutputDir(String dir) {
    state = state.copyWith(outputDir: dir);
  }

  /// Build output directory based on folder organization setting
  Future<String> _buildOutputDir(Track track, String folderOrganization) async {
    String baseDir = state.outputDir;

    if (folderOrganization == 'none') {
      return baseDir;
    }

    // Sanitize folder names (remove invalid characters)
    String sanitize(String name) {
      return name
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\.+$'), '') // Remove trailing dots
          .trim();
    }

    String subPath = '';
    switch (folderOrganization) {
      case 'artist':
        final artistName = sanitize(track.albumArtist ?? track.artistName);
        subPath = artistName;
        break;
      case 'album':
        final albumName = sanitize(track.albumName);
        subPath = albumName;
        break;
      case 'artist_album':
        final artistName = sanitize(track.albumArtist ?? track.artistName);
        final albumName = sanitize(track.albumName);
        subPath = '$artistName${Platform.pathSeparator}$albumName';
        break;
    }

    if (subPath.isNotEmpty) {
      final fullPath = '$baseDir${Platform.pathSeparator}$subPath';
      final dir = Directory(fullPath);
      if (!await dir.exists()) {
        await dir.create(recursive: true);
        _log.d('Created folder: $fullPath');
      }
      return fullPath;
    }

    return baseDir;
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
    // Sync settings before adding to queue
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
    _saveQueueToStorage(); // Persist queue

    if (!state.isProcessing) {
      // Run in microtask to not block UI
      Future.microtask(() => _processQueue());
    }

    return id;
  }

  void addMultipleToQueue(
    List<Track> tracks,
    String service, {
    String? qualityOverride,
  }) {
    // Sync settings before adding to queue
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
    _saveQueueToStorage(); // Persist queue

    if (!state.isProcessing) {
      // Run in microtask to not block UI
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
    final items = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(
          status: status,
          progress: progress ?? item.progress,
          speedMBps: speedMBps ?? item.speedMBps,
          filePath: filePath,
          error: error,
          errorType: errorType,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(items: items);

    // Persist queue when status changes to completed/failed/skipped (item removed from pending)
    if (status == DownloadStatus.completed ||
        status == DownloadStatus.failed ||
        status == DownloadStatus.skipped) {
      _saveQueueToStorage();
    }
  }

  void updateProgress(String id, double progress, {double? speedMBps}) {
    updateItemStatus(
      id,
      DownloadStatus.downloading,
      progress: progress,
      speedMBps: speedMBps,
    );
  }

  void cancelItem(String id) {
    updateItemStatus(id, DownloadStatus.skipped);
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
    _saveQueueToStorage(); // Persist queue
  }

  void clearAll() {
    state = state.copyWith(items: [], isPaused: false);
    _saveQueueToStorage(); // Clear persisted queue
  }

  /// Pause the download queue
  void pauseQueue() {
    if (state.isProcessing && !state.isPaused) {
      state = state.copyWith(isPaused: true);
      _notificationService.cancelDownloadNotification();
      _log.i('Queue paused');
    }
  }

  /// Resume the download queue
  void resumeQueue() {
    if (state.isPaused) {
      state = state.copyWith(isPaused: false);
      _log.i('Queue resumed');
      // If there are still queued items, continue processing
      if (state.queuedCount > 0 && !state.isProcessing) {
        Future.microtask(() => _processQueue());
      }
    }
  }

  /// Toggle pause/resume
  void togglePause() {
    if (state.isPaused) {
      resumeQueue();
    } else {
      pauseQueue();
    }
  }

  /// Retry a failed or skipped download
  void retryItem(String id) {
    final item = state.items.where((i) => i.id == id).firstOrNull;
    if (item == null) {
      _log.w('retryItem: Item not found: $id');
      return;
    }

    // Only retry if status is failed or skipped
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
    _saveQueueToStorage(); // Persist queue

    // Start processing if not already running
    if (!state.isProcessing) {
      _log.d('Starting queue processing for retry');
      Future.microtask(() => _processQueue());
    } else {
      _log.d('Queue already processing, item will be picked up');
    }
  }

  /// Remove a specific item from queue
  void removeItem(String id) {
    final items = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: items);
    _saveQueueToStorage(); // Persist queue
  }

  /// Run post-processing hooks on a downloaded file
  Future<void> _runPostProcessingHooks(String filePath, Track track) async {
    try {
      final settings = ref.read(settingsProvider);
      final extensionState = ref.read(extensionProvider);
      
      // Check if post-processing is enabled and there are extensions with hooks
      if (!settings.useExtensionProviders) return;
      
      final hasPostProcessing = extensionState.extensions.any(
        (e) => e.enabled && e.hasPostProcessing,
      );
      if (!hasPostProcessing) return;
      
      _log.d('Running post-processing hooks on: $filePath');
      
      // Build metadata map for post-processing
      final metadata = <String, dynamic>{
        'title': track.name,
        'artist': track.artistName,
        'album': track.albumName,
        'album_artist': track.albumArtist ?? track.artistName,
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
      // Don't fail the download if post-processing fails
    }
  }

  /// Embed metadata and cover to a FLAC file after M4A conversion
  Future<void> _embedMetadataAndCover(String flacPath, Track track) async {
    // Download cover first
    String? coverPath;
    final coverUrl = track.coverUrl;
    if (coverUrl != null && coverUrl.isNotEmpty) {
      try {
        final tempDir = await getTemporaryDirectory();
        final uniqueId =
            '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
        coverPath = '${tempDir.path}/cover_$uniqueId.jpg';

        // Download cover using HTTP
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

    // Use Go backend to embed metadata
    try {
      // Use FFmpeg to embed cover art AND text metadata
      // FFmpeg can embed cover art to FLAC and also set tags

      // Construct metadata map
      final metadata = <String, String>{
        'TITLE': track.name,
        'ARTIST': track.artistName,
        'ALBUM': track.albumName,
      };

      if (track.albumArtist != null) {
        metadata['ALBUMARTIST'] = track.albumArtist!;
      }

      if (track.trackNumber != null) {
        metadata['TRACKNUMBER'] = track.trackNumber.toString();
        metadata['TRACK'] = track.trackNumber.toString(); // Compatibility
      }

      if (track.discNumber != null) {
        metadata['DISCNUMBER'] = track.discNumber.toString();
        metadata['DISC'] = track.discNumber.toString(); // Compatibility
      }

      if (track.releaseDate != null) {
        metadata['DATE'] = track.releaseDate!;
        metadata['YEAR'] = track.releaseDate!.split('-').first;
      }

      if (track.isrc != null) {
        metadata['ISRC'] = track.isrc!;
      }

      _log.d('Metadata map content: $metadata');

      // Fetch Lyrics (Critical for M4A->FLAC conversion parity)
      // Since we are in the Flutter context, we can call the bridge to get lyrics
      // This ensures even converted files have lyrics embedded if available
      try {
        final lrcContent = await PlatformBridge.getLyricsLRC(
          track.id, // spotifyID
          track.name,
          track.artistName,
          filePath: '', // No local file path yet (processed in memory)
        );

        if (lrcContent.isNotEmpty) {
          metadata['LYRICS'] = lrcContent;
          metadata['UNSYNCEDLYRICS'] = lrcContent; // Fallback for some players
          _log.d('Lyrics fetched for embedding (${lrcContent.length} chars)');
        }
      } catch (e) {
        _log.w('Failed to fetch lyrics for embedding: $e');
      }

      _log.d('Generating tags for FLAC: $metadata');

      // Perform embedding (cover + text metadata)
      // Note: FFmpegService.embedMetadata handles safe temp file creation
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

      // Clean up cover file if it exists
      if (coverPath != null) {
        try {
          final coverFile = File(coverPath);
          if (await coverFile.exists()) {
            // In Android 10+ scoped storage, we can't easily delete if we didn't create it
            // in this session or if it's not in our app dir.
            // But coverPath is typically in temp dir now.
            await coverFile.delete();
          }
        } catch (_) {}
      }
    } catch (e) {
      _log.e('Failed to embed metadata: $e');
    }
  }

  Future<void> _processQueue() async {
    if (state.isProcessing) return; // Prevent multiple concurrent processing

    state = state.copyWith(isProcessing: true);
    _log.i('Starting queue processing...');

    // Track total items at start for notification
    _totalQueuedAtStart = state.items
        .where((i) => i.status == DownloadStatus.queued)
        .length;
    _completedInSession = 0;
    _failedInSession = 0;

    // Start foreground service to keep downloads running in background (Android only)
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

    // Ensure output directory is initialized before processing
    if (state.outputDir.isEmpty) {
      _log.d('Output dir empty, initializing...');
      await _initOutputDir();
    }

    // If still empty, use fallback
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

    // Use parallel processing if concurrentDownloads > 1
    if (state.concurrentDownloads > 1) {
      await _processQueueParallel();
    } else {
      await _processQueueSequential();
    }

    _stopProgressPolling();

    // Stop foreground service (Android only)
    if (Platform.isAndroid) {
      try {
        await PlatformBridge.stopDownloadService();
        _log.d('Foreground service stopped');
      } catch (e) {
        _log.e('Failed to stop foreground service: $e');
      }
    }

    // Final cleanup after queue finishes
    if (_downloadCount > 0) {
      _log.d('Final connection cleanup...');
      try {
        await PlatformBridge.cleanupConnections();
      } catch (e) {
        _log.e('Final cleanup failed: $e');
      }
      _downloadCount = 0;
    }

    // Show queue completion notification
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

    // Check if there are new queued items (e.g., from retry) and restart if needed
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

  /// Sequential download processing (uses multi-progress system with single item)
  Future<void> _processQueueSequential() async {
    // Start multi-progress polling (works for both sequential and parallel)
    _startMultiProgressPolling();

    while (true) {
      // Check if paused
      if (state.isPaused) {
        _log.d('Queue is paused, waiting...');
        await Future.delayed(const Duration(milliseconds: 500));
        continue;
      }

      // Re-read state to get latest items (important for retry)
      final currentItems = state.items;
      final nextItem = currentItems.firstWhere(
        (item) => item.status == DownloadStatus.queued,
        orElse: () => DownloadItem(
          id: '',
          track: const Track(
            id: '',
            name: '',
            artistName: '',
            albumName: '',
            duration: 0,
          ),
          service: '',
          createdAt: DateTime.now(),
        ),
      );

      if (nextItem.id.isEmpty) {
        _log.d(
          'No more items to process (checked ${currentItems.length} items)',
        );
        break;
      }

      _log.d(
        'Processing next item: ${nextItem.track.name} (id: ${nextItem.id})',
      );
      await _downloadSingleItem(nextItem);

      // Clear item progress after download completes
      PlatformBridge.clearItemProgress(nextItem.id).catchError((_) {});
    }

    // Stop polling when queue is done
    _stopProgressPolling();
  }

  /// Parallel download processing with worker pool
  Future<void> _processQueueParallel() async {
    final maxConcurrent = state.concurrentDownloads;
    final activeDownloads = <String, Future<void>>{}; // Map item ID to future

    // Start multi-progress polling (shared with sequential mode)
    _startMultiProgressPolling();

    while (true) {
      // Check if paused - don't start new downloads but let active ones finish
      if (state.isPaused) {
        _log.d('Queue is paused, waiting for active downloads...');
        if (activeDownloads.isNotEmpty) {
          await Future.any(activeDownloads.values);
        } else {
          await Future.delayed(const Duration(milliseconds: 500));
        }
        continue;
      }

      // Get queued items
      final queuedItems = state.items
          .where((item) => item.status == DownloadStatus.queued)
          .toList();

      if (queuedItems.isEmpty && activeDownloads.isEmpty) {
        _log.d('No more items to process');
        break;
      }

      // Start new downloads up to max concurrent limit
      while (activeDownloads.length < maxConcurrent &&
          queuedItems.isNotEmpty &&
          !state.isPaused) {
        final item = queuedItems.removeAt(0);

        // Mark as downloading immediately to prevent double-processing
        updateItemStatus(item.id, DownloadStatus.downloading);

        // Create the download future
        final future = _downloadSingleItem(item).whenComplete(() {
          activeDownloads.remove(item.id);
          // Clear item progress after download completes
          PlatformBridge.clearItemProgress(item.id).catchError((_) {});
        });

        activeDownloads[item.id] = future;
        _log.d(
          'Started parallel download: ${item.track.name} (${activeDownloads.length}/$maxConcurrent active)',
        );
      }

      // Wait for at least one download to complete before checking for more
      if (activeDownloads.isNotEmpty) {
        await Future.any(activeDownloads.values);
      }
    }

    // Wait for all remaining downloads to complete
    if (activeDownloads.isNotEmpty) {
      await Future.wait(activeDownloads.values);
    }

    // Stop polling when queue is done
    _stopProgressPolling();
  }

  /// Download a single item (used by both sequential and parallel processing)
  Future<void> _downloadSingleItem(DownloadItem item) async {
    _log.d('Processing: ${item.track.name} by ${item.track.artistName}');
    _log.d('Cover URL: ${item.track.coverUrl}');

    // Set currentDownload for UI reference
    state = state.copyWith(currentDownload: item);

    updateItemStatus(item.id, DownloadStatus.downloading);

    try {
      // Get folder organization setting and build output directory
      final settings = ref.read(settingsProvider);

      // Metadata Enrichment:
      // If track number is missing/0 (common from Search results), fetch full metadata
      // This ensures the downloaded file has correct tags (Track, Disc, Year)
      Track trackToDownload = item.track;
      // Enrich metadata if ISRC or track number is missing (common from Search results)
      // ISRC is critical for accurate track matching on streaming services
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
            // Parse Go backend response (snake_case) to Track
            final trackData = fullData['track'];
            _log.d('Track data type: ${trackData.runtimeType}');
            if (trackData is Map<String, dynamic>) {
              final data = trackData;
              _log.d('Track data keys: ${data.keys.toList()}');
              _log.d('ISRC from API: ${data['isrc']}');
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
                // duration_ms from Go is in milliseconds, Track.duration is in seconds
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
              );
              _log.d(
                'Metadata enriched: Track ${trackToDownload.trackNumber}, Disc ${trackToDownload.discNumber}, ISRC ${trackToDownload.isrc}',
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

      // Log cover URL for debugging CSV import issues
      _log.d('Track coverUrl after enrichment: ${trackToDownload.coverUrl}');

      final outputDir = await _buildOutputDir(
        trackToDownload,
        settings.folderOrganization,
      );

      // Use quality override if set, otherwise use default from settings
      final quality = item.qualityOverride ?? state.audioQuality;

      Map<String, dynamic> result;

      // Check if extension providers should be used
      final extensionState = ref.read(extensionProvider);
      final hasActiveExtensions = extensionState.extensions.any((e) => e.enabled);
      final useExtensions = settings.useExtensionProviders && hasActiveExtensions;

      if (useExtensions) {
        // Use extension providers (includes fallback to built-in services)
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
          albumArtist: trackToDownload.albumArtist,
          coverUrl: trackToDownload.coverUrl,
          outputDir: outputDir,
          filenameFormat: state.filenameFormat,
          quality: quality,
          trackNumber: trackToDownload.trackNumber ?? 1,
          discNumber: trackToDownload.discNumber ?? 1,
          releaseDate: trackToDownload.releaseDate,
          itemId: item.id,
          durationMs: trackToDownload.duration,
          source: trackToDownload.source, // Pass extension ID that provided this track
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
          albumArtist: trackToDownload.albumArtist,
          coverUrl: trackToDownload.coverUrl,
          outputDir: outputDir,
          filenameFormat: state.filenameFormat,
          quality: quality,
          trackNumber: trackToDownload.trackNumber ?? 1,
          discNumber: trackToDownload.discNumber ?? 1,
          releaseDate: trackToDownload.releaseDate,
          preferredService: item.service,
          itemId: item.id, // Pass item ID for progress tracking
          durationMs:
              trackToDownload.duration, // Duration in ms for verification
        );
      } else {
        result = await PlatformBridge.downloadTrack(
          isrc: trackToDownload.isrc ?? '',
          service: item.service,
          spotifyId: trackToDownload.id,
          trackName: trackToDownload.name,
          artistName: trackToDownload.artistName,
          albumName: trackToDownload.albumName,
          albumArtist: trackToDownload.albumArtist,
          coverUrl: trackToDownload.coverUrl,
          outputDir: outputDir,
          filenameFormat: state.filenameFormat,
          quality: quality,
          trackNumber: trackToDownload.trackNumber ?? 1,
          discNumber: trackToDownload.discNumber ?? 1,
          releaseDate: trackToDownload.releaseDate,
          itemId: item.id, // Pass item ID for progress tracking
          durationMs:
              trackToDownload.duration, // Duration in ms for verification
        );
      }

      _log.d('Result: $result');

      // Check if item was cancelled while downloading
      final currentItem = state.items.firstWhere(
        (i) => i.id == item.id,
        orElse: () => item,
      );
      if (currentItem.status == DownloadStatus.skipped) {
        _log.i('Download was cancelled, skipping result processing');
        // Delete the downloaded file if it exists
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
        _log.i('Download success, file: $filePath');

        // Get actual quality from response (if available)
        final actualBitDepth = result['actual_bit_depth'] as int?;
        final actualSampleRate = result['actual_sample_rate'] as int?;
        String actualQuality = quality; // Default to requested quality

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

        // M4A files from Tidal DASH streams - try to convert to FLAC
        // M4A files from Tidal DASH streams - try to convert to FLAC
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

                  // After conversion, embed metadata and cover to the new FLAC file
                  _log.d('Embedding metadata and cover to converted FLAC...');
                  try {
                    // Update track with actual metadata from backend result (if available)
                    // This creates the most accurate metadata possible (from the service itself)
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

                      // Create updated track object with safety check for 0/null
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
                        albumArtist: trackToDownload.albumArtist,
                        coverUrl: trackToDownload.coverUrl,
                        duration: trackToDownload.duration,
                        isrc: trackToDownload.isrc,
                        trackNumber: newTrackNumber,
                        discNumber: newDiscNumber,
                        releaseDate: backendYear ?? trackToDownload.releaseDate,
                        deezerId: trackToDownload.deezerId,
                        availability: trackToDownload.availability,
                      );
                    }

                    // Use enriched/updated track for metadata embedding
                    await _embedMetadataAndCover(flacPath, finalTrack);
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
            // Keep the M4A file if conversion fails
          }
        }

        // Check again if cancelled before updating status and adding to history
        final itemAfterDownload = state.items.firstWhere(
          (i) => i.id == item.id,
          orElse: () => item,
        );
        if (itemAfterDownload.status == DownloadStatus.skipped) {
          _log.i('Download was cancelled during finalization, cleaning up');
          // Delete the downloaded file
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

        updateItemStatus(
          item.id,
          DownloadStatus.completed,
          progress: 1.0,
          filePath: filePath,
        );

        // Run post-processing hooks if enabled
        if (filePath != null) {
          await _runPostProcessingHooks(filePath, trackToDownload);
        }

        // Increment completed counter
        _completedInSession++;

        // Show completion notification for this track
        await _notificationService.showDownloadComplete(
          trackName: item.track.name,
          artistName: item.track.artistName,
          completedCount: _completedInSession,
          totalCount: _totalQueuedAtStart,
        );

        if (filePath != null) {
          // Extract metadata from backend result (most accurate source)
          final backendTitle = result['title'] as String?;
          final backendArtist = result['artist'] as String?;
          final backendAlbum = result['album'] as String?;
          final backendYear = result['release_date'] as String?;
          final backendTrackNum = result['track_number'] as int?;
          final backendDiscNum = result['disc_number'] as int?;
          final backendBitDepth = result['actual_bit_depth'] as int?;
          final backendSampleRate = result['actual_sample_rate'] as int?;
          final backendISRC = result['isrc'] as String?;

          // Log cover URL for debugging
          _log.d('Saving to history - coverUrl: ${trackToDownload.coverUrl}');

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
                  albumArtist: trackToDownload.albumArtist,
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
                  bitDepth: backendBitDepth,
                  sampleRate: backendSampleRate,
                ),
              );

          // Auto-remove completed item from queue (it's now in history)
          removeItem(item.id);
        }
      } else {
        final errorMsg = result['error'] as String? ?? 'Download failed';
        final errorTypeStr = result['error_type'] as String? ?? 'unknown';

        // Convert error type string to enum
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

      // Increment download counter and cleanup connections periodically
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
      _log.e('Exception: $e', e, stackTrace);

      String errorMsg = e.toString();
      DownloadErrorType errorType = DownloadErrorType.unknown;

      // Check for specific Deezer fallback error
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
