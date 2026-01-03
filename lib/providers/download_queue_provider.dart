import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:spotiflac_android/models/download_item.dart';
import 'package:spotiflac_android/models/settings.dart';
import 'package:spotiflac_android/models/track.dart';
import 'package:spotiflac_android/providers/settings_provider.dart';
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
  };

  factory DownloadHistoryItem.fromJson(Map<String, dynamic> json) => DownloadHistoryItem(
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
  bool isDownloaded(String spotifyId) => _downloadedSpotifyIds.contains(spotifyId);

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
        final items = jsonList.map((e) => DownloadHistoryItem.fromJson(e as Map<String, dynamic>)).toList();
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
final downloadHistoryProvider = NotifierProvider<DownloadHistoryNotifier, DownloadHistoryState>(
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

  int get queuedCount => items.where((i) => i.status == DownloadStatus.queued || i.status == DownloadStatus.downloading).length;
  int get completedCount => items.where((i) => i.status == DownloadStatus.completed).length;
  int get failedCount => items.where((i) => i.status == DownloadStatus.failed).length;
  int get activeDownloadsCount => items.where((i) => i.status == DownloadStatus.downloading).length;
}

// Download Queue Notifier (Riverpod 3.x)
class DownloadQueueNotifier extends Notifier<DownloadQueueState> {
  Timer? _progressTimer;
  int _downloadCount = 0; // Counter for connection cleanup
  static const _cleanupInterval = 50; // Cleanup every 50 downloads
  static const _queueStorageKey = 'download_queue'; // Storage key for queue persistence
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
        final items = jsonList.map((e) => DownloadItem.fromJson(e as Map<String, dynamic>)).toList();
        
        // Reset downloading items to queued (they were interrupted)
        final restoredItems = items.map((item) {
          if (item.status == DownloadStatus.downloading) {
            return item.copyWith(status: DownloadStatus.queued, progress: 0);
          }
          return item;
        }).toList();
        
        // Only restore queued/downloading items (not completed/failed/skipped)
        final pendingItems = restoredItems.where((item) => 
          item.status == DownloadStatus.queued
        ).toList();
        
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
      final pendingItems = state.items.where((item) => 
        item.status == DownloadStatus.queued || 
        item.status == DownloadStatus.downloading
      ).toList();
      
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
    _progressTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
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
          final isDownloading = itemProgress['is_downloading'] as bool? ?? false;
          final status = itemProgress['status'] as String? ?? 'downloading';
          
          // Check if status is "finalizing" (embedding metadata)
          // Only trust finalizing status if bytesTotal > 0 (download actually happened)
          if (status == 'finalizing' && bytesTotal > 0) {
            updateItemStatus(itemId, DownloadStatus.finalizing, progress: 1.0);
            
            // Track finalizing item for notification
            final currentItem = state.items.where((i) => i.id == itemId).firstOrNull;
            if (currentItem != null) {
              hasFinalizingItem = true;
              finalizingTrackName = currentItem.track.name;
              finalizingArtistName = currentItem.track.artistName;
            }
            continue;
          }
          
          if (isDownloading && bytesTotal > 0) {
            final percentage = bytesReceived / bytesTotal;
            updateProgress(itemId, percentage);
            
            // Log progress for each item
            final mbReceived = bytesReceived / (1024 * 1024);
            final mbTotal = bytesTotal / (1024 * 1024);
            _log.d('Progress [$itemId]: ${(percentage * 100).toStringAsFixed(1)}% (${mbReceived.toStringAsFixed(2)}/${mbTotal.toStringAsFixed(2)} MB)');
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
          final downloadingItems = state.items.where((i) => i.status == DownloadStatus.downloading).toList();
          if (downloadingItems.isNotEmpty) {
            // Show single track name if only 1 download, otherwise show count
            final trackName = downloadingItems.length == 1 
                ? downloadingItems.first.track.name 
                : '${downloadingItems.length} downloads';
            final artistName = downloadingItems.length == 1 
                ? downloadingItems.first.track.artistName 
                : 'Downloading...';
            
            _notificationService.showDownloadProgress(
              trackName: trackName,
              artistName: artistName,
              progress: bytesReceived,
              total: bytesTotal > 0 ? bytesTotal : 1,
            );
            
            // Update foreground service notification (Android)
            if (Platform.isAndroid) {
              PlatformBridge.updateDownloadServiceProgress(
                trackName: downloadingItems.first.track.name,
                artistName: downloadingItems.first.track.artistName,
                progress: bytesReceived,
                total: bytesTotal > 0 ? bytesTotal : 1,
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
            final musicDir = Directory('${dir.parent.parent.parent.parent.path}/Music/SpotiFLAC');
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
      outputDir: settings.downloadDirectory.isNotEmpty ? settings.downloadDirectory : state.outputDir,
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
    
    final id = '${track.isrc ?? track.id}-${DateTime.now().millisecondsSinceEpoch}';
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

  void addMultipleToQueue(List<Track> tracks, String service, {String? qualityOverride}) {
    // Sync settings before adding to queue
    final settings = ref.read(settingsProvider);
    updateSettings(settings);
    
    final newItems = tracks.map((track) {
      final id = '${track.isrc ?? track.id}-${DateTime.now().millisecondsSinceEpoch}';
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

  void updateItemStatus(String id, DownloadStatus status, {double? progress, String? filePath, String? error}) {
    final items = state.items.map((item) {
      if (item.id == id) {
        return item.copyWith(
          status: status,
          progress: progress ?? item.progress,
          filePath: filePath,
          error: error,
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

  void updateProgress(String id, double progress) {
    updateItemStatus(id, DownloadStatus.downloading, progress: progress);
  }

  void cancelItem(String id) {
    updateItemStatus(id, DownloadStatus.skipped);
  }

  void clearCompleted() {
    final items = state.items.where((item) =>
      item.status != DownloadStatus.completed &&
      item.status != DownloadStatus.failed &&
      item.status != DownloadStatus.skipped
    ).toList();

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

  /// Retry a failed download
  void retryItem(String id) {
    final items = state.items.map((item) {
      if (item.id == id && item.status == DownloadStatus.failed) {
        return item.copyWith(status: DownloadStatus.queued, progress: 0, error: null);
      }
      return item;
    }).toList();
    state = state.copyWith(items: items);
    _saveQueueToStorage(); // Persist queue
    
    // Start processing if not already
    if (!state.isProcessing) {
      Future.microtask(() => _processQueue());
    }
  }

  /// Remove a specific item from queue
  void removeItem(String id) {
    final items = state.items.where((item) => item.id != id).toList();
    state = state.copyWith(items: items);
    _saveQueueToStorage(); // Persist queue
  }

  /// Embed metadata and cover to a FLAC file after M4A conversion
  Future<void> _embedMetadataAndCover(String flacPath, Track track) async {
    // Download cover first
    String? coverPath;
    if (track.coverUrl != null && track.coverUrl!.isNotEmpty) {
      coverPath = '$flacPath.cover.jpg';
      try {
        // Download cover using HTTP
        final httpClient = HttpClient();
        final request = await httpClient.getUrl(Uri.parse(track.coverUrl!));
        final response = await request.close();
        if (response.statusCode == 200) {
          final file = File(coverPath);
          final sink = file.openWrite();
          await response.pipe(sink);
          await sink.close();
          _log.d('Cover downloaded to: $coverPath');
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
      // For now, we'll use FFmpeg to embed cover since Go backend expects to download the file
      // FFmpeg can embed cover art to FLAC
      if (coverPath != null && await File(coverPath).exists()) {
        final tempOutput = '$flacPath.tmp';
        final command = '-i "$flacPath" -i "$coverPath" -map 0:a -map 1:0 -c copy -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" -disposition:v attached_pic "$tempOutput" -y';
        
        final session = await FFmpegKit.execute(command);
        final returnCode = await session.getReturnCode();
        
        if (ReturnCode.isSuccess(returnCode)) {
          // Replace original with temp
          await File(flacPath).delete();
          await File(tempOutput).rename(flacPath);
          _log.d('Cover embedded via FFmpeg');
        } else {
          // Try alternative method using metaflac-style embedding
          _log.w('FFmpeg cover embed failed, trying alternative...');
          // Clean up temp file if exists
          final tempFile = File(tempOutput);
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
        
        // Clean up cover file
        try {
          await File(coverPath).delete();
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
    _totalQueuedAtStart = state.items.where((i) => i.status == DownloadStatus.queued).length;
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
    _log.i('Queue stats - completed: $_completedInSession, failed: $_failedInSession, totalAtStart: $_totalQueuedAtStart');
    if (_totalQueuedAtStart > 0) {
      await _notificationService.showQueueComplete(
        completedCount: _completedInSession,
        failedCount: _failedInSession,
      );
    }
    
    _log.i('Queue processing finished');
    state = state.copyWith(isProcessing: false, currentDownload: null);
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
      
      final nextItem = state.items.firstWhere(
        (item) => item.status == DownloadStatus.queued,
        orElse: () => DownloadItem(
          id: '',
          track: const Track(id: '', name: '', artistName: '', albumName: '', duration: 0),
          service: '',
          createdAt: DateTime.now(),
        ),
      );

      if (nextItem.id.isEmpty) {
        _log.d('No more items to process');
        break;
      }

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
      final queuedItems = state.items.where((item) => item.status == DownloadStatus.queued).toList();
      
      if (queuedItems.isEmpty && activeDownloads.isEmpty) {
        _log.d('No more items to process');
        break;
      }
      
      // Start new downloads up to max concurrent limit
      while (activeDownloads.length < maxConcurrent && queuedItems.isNotEmpty && !state.isPaused) {
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
        _log.d('Started parallel download: ${item.track.name} (${activeDownloads.length}/$maxConcurrent active)');
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
      final outputDir = await _buildOutputDir(item.track, settings.folderOrganization);
      
      // Use quality override if set, otherwise use default from settings
      final quality = item.qualityOverride ?? state.audioQuality;
      
      Map<String, dynamic> result;

      if (state.autoFallback) {
        _log.d('Using auto-fallback mode');
        _log.d('Quality: $quality${item.qualityOverride != null ? ' (override)' : ''}');
        _log.d('Output dir: $outputDir');
        result = await PlatformBridge.downloadWithFallback(
          isrc: item.track.isrc ?? '',
          spotifyId: item.track.id,
          trackName: item.track.name,
          artistName: item.track.artistName,
          albumName: item.track.albumName,
          albumArtist: item.track.albumArtist,
          coverUrl: item.track.coverUrl,
          outputDir: outputDir,
          filenameFormat: state.filenameFormat,
          quality: quality,
          trackNumber: item.track.trackNumber ?? 1,
          discNumber: item.track.discNumber ?? 1,
          releaseDate: item.track.releaseDate,
          preferredService: item.service,
          itemId: item.id, // Pass item ID for progress tracking
        );
      } else {
        result = await PlatformBridge.downloadTrack(
          isrc: item.track.isrc ?? '',
          service: item.service,
          spotifyId: item.track.id,
          trackName: item.track.name,
          artistName: item.track.artistName,
          albumName: item.track.albumName,
          albumArtist: item.track.albumArtist,
          coverUrl: item.track.coverUrl,
          outputDir: outputDir,
          filenameFormat: state.filenameFormat,
          quality: quality,
          trackNumber: item.track.trackNumber ?? 1,
          discNumber: item.track.discNumber ?? 1,
          releaseDate: item.track.releaseDate,
          itemId: item.id, // Pass item ID for progress tracking
        );
      }
      
      _log.d('Result: $result');
      
      // Check if item was cancelled while downloading
      final currentItem = state.items.firstWhere((i) => i.id == item.id, orElse: () => item);
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
              ? (actualSampleRate / 1000).toStringAsFixed(actualSampleRate % 1000 == 0 ? 0 : 1)
              : '?';
          actualQuality = '$actualBitDepth-bit/${sampleRateKHz}kHz';
          _log.i('Actual quality: $actualQuality');
        }
        
        // Check if file is M4A (DASH stream from Tidal) and needs remuxing to FLAC
        if (filePath != null && filePath.endsWith('.m4a')) {
          _log.d('Converting M4A to FLAC...');
          updateItemStatus(item.id, DownloadStatus.downloading, progress: 0.9);
          final flacPath = await FFmpegService.convertM4aToFlac(filePath);
          if (flacPath != null) {
            filePath = flacPath;
            _log.d('Converted to: $flacPath');
            
            // After conversion, embed metadata and cover to the new FLAC file
            _log.d('Embedding metadata and cover to converted FLAC...');
            try {
              await _embedMetadataAndCover(
                flacPath,
                item.track,
              );
              _log.d('Metadata and cover embedded successfully');
            } catch (e) {
              _log.w('Warning: Failed to embed metadata/cover: $e');
            }
          }
        }
        
        // Check again if cancelled before updating status and adding to history
        final itemAfterDownload = state.items.firstWhere((i) => i.id == item.id, orElse: () => item);
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
          ref.read(downloadHistoryProvider.notifier).addToHistory(
            DownloadHistoryItem(
              id: item.id,
              trackName: item.track.name,
              artistName: item.track.artistName,
              albumName: item.track.albumName,
              albumArtist: item.track.albumArtist,
              coverUrl: item.track.coverUrl,
              filePath: filePath,
              service: result['service'] as String? ?? item.service,
              downloadedAt: DateTime.now(),
              // Additional metadata
              isrc: item.track.isrc,
              spotifyId: item.track.id,
              trackNumber: item.track.trackNumber,
              discNumber: item.track.discNumber,
              duration: item.track.duration,
              releaseDate: item.track.releaseDate,
              quality: actualQuality,
            ),
          );
          
          // Auto-remove completed item from queue (it's now in history)
          removeItem(item.id);
        }
      } else {
        final errorMsg = result['error'] as String? ?? 'Download failed';
        _log.e('Download failed: $errorMsg');
        updateItemStatus(
          item.id,
          DownloadStatus.failed,
          error: errorMsg,
        );
        _failedInSession++;
      }
      
      // Increment download counter and cleanup connections periodically
      _downloadCount++;
      if (_downloadCount % _cleanupInterval == 0) {
        _log.d('Cleaning up idle connections (after $_downloadCount downloads)...');
        try {
          await PlatformBridge.cleanupConnections();
        } catch (e) {
          _log.e('Connection cleanup failed: $e');
        }
      }
    } catch (e, stackTrace) {
      _log.e('Exception: $e', e, stackTrace);
      updateItemStatus(
        item.id,
        DownloadStatus.failed,
        error: e.toString(),
      );
      _failedInSession++;
    }
  }
}

final downloadQueueProvider = NotifierProvider<DownloadQueueNotifier, DownloadQueueState>(
  DownloadQueueNotifier.new,
);
