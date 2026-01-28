import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:spotiflac_android/models/webdav_config.dart';
import 'package:spotiflac_android/services/webdav_service.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('WebDavUploadQueue');

const _configKey = 'webdav_config';
const _queueKey = 'webdav_upload_queue';

class WebDavState {
  final WebDavConfig config;
  final List<WebDavUploadItem> queue;
  final bool isProcessing;
  final WebDavUploadItem? currentUpload;

  const WebDavState({
    this.config = const WebDavConfig(),
    this.queue = const [],
    this.isProcessing = false,
    this.currentUpload,
  });

  WebDavState copyWith({
    WebDavConfig? config,
    List<WebDavUploadItem>? queue,
    bool? isProcessing,
    WebDavUploadItem? currentUpload,
    bool clearCurrentUpload = false,
  }) {
    return WebDavState(
      config: config ?? this.config,
      queue: queue ?? this.queue,
      isProcessing: isProcessing ?? this.isProcessing,
      currentUpload: clearCurrentUpload
          ? null
          : (currentUpload ?? this.currentUpload),
    );
  }

  int get pendingCount =>
      queue.where((i) => i.status == WebDavUploadStatus.pending).length;
  int get uploadingCount =>
      queue.where((i) => i.status == WebDavUploadStatus.uploading).length;
  int get completedCount =>
      queue.where((i) => i.status == WebDavUploadStatus.completed).length;
  int get failedCount =>
      queue.where((i) => i.status == WebDavUploadStatus.failed).length;

  List<WebDavUploadItem> get activeItems =>
      queue.where((i) => i.status != WebDavUploadStatus.completed).toList();

  List<WebDavUploadItem> get failedItems =>
      queue.where((i) => i.status == WebDavUploadStatus.failed).toList();
}

class WebDavNotifier extends Notifier<WebDavState> {
  final Future<SharedPreferences> _prefs = SharedPreferences.getInstance();
  final WebDavService _service = WebDavService();
  Timer? _processTimer;

  @override
  WebDavState build() {
    ref.onDispose(() {
      _processTimer?.cancel();
    });
    _loadConfig();
    _loadQueue();
    return const WebDavState();
  }

  Future<void> _loadConfig() async {
    final prefs = await _prefs;
    final json = prefs.getString(_configKey);
    if (json != null) {
      try {
        final config = WebDavConfig.fromJson(jsonDecode(json));
        state = state.copyWith(config: config);
        _service.configure(config);
        _log.d('Loaded WebDAV config: enabled=${config.enabled}');
      } catch (e) {
        _log.e('Failed to load WebDAV config: $e');
      }
    }
  }

  Future<void> _loadQueue() async {
    final prefs = await _prefs;
    final json = prefs.getString(_queueKey);
    if (json != null) {
      try {
        final List<dynamic> list = jsonDecode(json);
        final queue = list.map((e) => WebDavUploadItem.fromJson(e)).toList();

        // Reset any uploading items to pending (app may have been killed mid-upload)
        final resetQueue = queue.map((item) {
          if (item.status == WebDavUploadStatus.uploading) {
            return item.copyWith(status: WebDavUploadStatus.pending);
          }
          return item;
        }).toList();

        state = state.copyWith(queue: resetQueue);
        _log.d('Loaded ${resetQueue.length} items from WebDAV upload queue');

        // Start processing if there are pending items
        if (state.config.enabled && state.pendingCount > 0) {
          _startProcessing();
        }
      } catch (e) {
        _log.e('Failed to load WebDAV queue: $e');
      }
    }
  }

  Future<void> _saveConfig() async {
    final prefs = await _prefs;
    await prefs.setString(_configKey, jsonEncode(state.config.toJson()));
  }

  Future<void> _saveQueue() async {
    final prefs = await _prefs;
    final json = jsonEncode(state.queue.map((e) => e.toJson()).toList());
    await prefs.setString(_queueKey, json);
  }

  // Configuration methods
  Future<void> updateConfig(WebDavConfig config) async {
    state = state.copyWith(config: config);
    _service.configure(config);
    await _saveConfig();

    if (config.enabled && config.isConfigured && state.pendingCount > 0) {
      _startProcessing();
    }
  }

  void setEnabled(bool enabled) {
    updateConfig(state.config.copyWith(enabled: enabled));
  }

  void setServerUrl(String url) {
    updateConfig(state.config.copyWith(serverUrl: url.trim()));
  }

  void setUsername(String username) {
    updateConfig(state.config.copyWith(username: username.trim()));
  }

  void setPassword(String password) {
    updateConfig(state.config.copyWith(password: password));
  }

  void setRemotePath(String path) {
    var cleanPath = path.trim();
    if (!cleanPath.startsWith('/')) {
      cleanPath = '/$cleanPath';
    }
    updateConfig(state.config.copyWith(remotePath: cleanPath));
  }

  void setDeleteLocalAfterUpload(bool delete) {
    updateConfig(state.config.copyWith(deleteLocalAfterUpload: delete));
  }

  void setRetryOnFailure(bool retry) {
    updateConfig(state.config.copyWith(retryOnFailure: retry));
  }

  void setMaxRetries(int maxRetries) {
    updateConfig(state.config.copyWith(maxRetries: maxRetries.clamp(1, 10)));
  }

  Future<({bool success, String? error})> testConnection() async {
    _service.configure(state.config);
    return await _service.testConnection();
  }

  // Queue methods
  Future<void> addToQueue({
    required String localPath,
    required String trackName,
    required String artistName,
    String? albumName,
  }) async {
    if (!state.config.enabled || !state.config.isConfigured) {
      _log.d('WebDAV not enabled or configured, skipping upload queue');
      return;
    }

    // Check if file exists
    final file = File(localPath);
    if (!await file.exists()) {
      _log.w('File does not exist, not adding to queue: $localPath');
      return;
    }

    final remotePath = _service.buildRemotePath(
      localPath,
      albumName: albumName,
      artistName: artistName,
    );

    final item = WebDavUploadItem(
      id: '${DateTime.now().millisecondsSinceEpoch}_${localPath.hashCode}',
      localPath: localPath,
      remotePath: remotePath,
      trackName: trackName,
      artistName: artistName,
      albumName: albumName,
      createdAt: DateTime.now(),
    );

    state = state.copyWith(queue: [...state.queue, item]);
    await _saveQueue();

    _log.i('Added to WebDAV upload queue: $trackName');
    _startProcessing();
  }

  void removeFromQueue(String id) {
    state = state.copyWith(
      queue: state.queue.where((i) => i.id != id).toList(),
    );
    _saveQueue();
  }

  void clearCompleted() {
    state = state.copyWith(
      queue: state.queue
          .where((i) => i.status != WebDavUploadStatus.completed)
          .toList(),
    );
    _saveQueue();
  }

  void clearAll() {
    state = state.copyWith(queue: []);
    _saveQueue();
  }

  Future<void> retryFailed() async {
    final updatedQueue = state.queue.map((item) {
      if (item.status == WebDavUploadStatus.failed) {
        return item.copyWith(
          status: WebDavUploadStatus.pending,
          clearError: true,
          retryCount: 0,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(queue: updatedQueue);
    await _saveQueue();
    _startProcessing();
  }

  Future<void> retryItem(String id) async {
    final updatedQueue = state.queue.map((item) {
      if (item.id == id && item.status == WebDavUploadStatus.failed) {
        return item.copyWith(
          status: WebDavUploadStatus.pending,
          clearError: true,
        );
      }
      return item;
    }).toList();

    state = state.copyWith(queue: updatedQueue);
    await _saveQueue();
    _startProcessing();
  }

  void _startProcessing() {
    if (state.isProcessing) return;
    if (!state.config.enabled || !state.config.isConfigured) return;

    _processTimer?.cancel();
    _processTimer = Timer(const Duration(milliseconds: 500), () {
      _processQueue();
    });
  }

  Future<void> _processQueue() async {
    if (state.isProcessing) return;
    if (!state.config.enabled || !state.config.isConfigured) return;

    state = state.copyWith(isProcessing: true);

    // Process items in a loop to catch any new items added during processing
    while (state.config.enabled && state.config.isConfigured) {
      final pendingItems = state.queue
          .where((i) => i.status == WebDavUploadStatus.pending)
          .toList();

      if (pendingItems.isEmpty) {
        _log.d('No pending items in upload queue');
        break;
      }

      // Process one item at a time to allow new items to be picked up
      await _uploadItem(pendingItems.first);
    }

    state = state.copyWith(isProcessing: false, clearCurrentUpload: true);
  }

  Future<void> _uploadItem(WebDavUploadItem item) async {
    _log.i('Starting upload: ${item.trackName}');

    // Update status to uploading
    _updateItem(
      item.id,
      (i) => i.copyWith(status: WebDavUploadStatus.uploading, progress: 0.0),
    );
    state = state.copyWith(
      currentUpload: state.queue.firstWhere((i) => i.id == item.id),
    );

    try {
      await _service.uploadFile(
        item.localPath,
        item.remotePath,
        onProgress: (progress) {
          _updateItem(item.id, (i) => i.copyWith(progress: progress));
          final updatedItem = state.queue.firstWhere(
            (i) => i.id == item.id,
            orElse: () => item,
          );
          state = state.copyWith(currentUpload: updatedItem);
        },
      );

      // Upload successful
      _updateItem(
        item.id,
        (i) => i.copyWith(
          status: WebDavUploadStatus.completed,
          progress: 1.0,
          completedAt: DateTime.now(),
        ),
      );

      _log.i('Upload completed: ${item.trackName}');

      // Delete local file if configured
      if (state.config.deleteLocalAfterUpload) {
        final deleted = await _service.deleteLocalFile(item.localPath);
        if (deleted) {
          _log.d('Deleted local file after upload: ${item.localPath}');
        }
      }

      await _saveQueue();
    } catch (e) {
      _log.e('Upload failed: ${item.trackName} - $e');

      final currentItem = state.queue.firstWhere(
        (i) => i.id == item.id,
        orElse: () => item,
      );
      final newRetryCount = currentItem.retryCount + 1;

      if (state.config.retryOnFailure &&
          newRetryCount < state.config.maxRetries) {
        // Mark as pending for retry
        _updateItem(
          item.id,
          (i) => i.copyWith(
            status: WebDavUploadStatus.pending,
            progress: 0.0,
            retryCount: newRetryCount,
            error: 'Retry $newRetryCount/${state.config.maxRetries}: $e',
          ),
        );
        _log.d(
          'Will retry upload ($newRetryCount/${state.config.maxRetries}): ${item.trackName}',
        );
      } else {
        // Mark as failed
        _updateItem(
          item.id,
          (i) => i.copyWith(
            status: WebDavUploadStatus.failed,
            error: e.toString(),
            retryCount: newRetryCount,
          ),
        );
      }

      await _saveQueue();
    }
  }

  void _updateItem(
    String id,
    WebDavUploadItem Function(WebDavUploadItem) updater,
  ) {
    state = state.copyWith(
      queue: state.queue.map((item) {
        if (item.id == id) {
          return updater(item);
        }
        return item;
      }).toList(),
    );
  }
}

final webDavProvider = NotifierProvider<WebDavNotifier, WebDavState>(
  WebDavNotifier.new,
);
