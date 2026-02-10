import 'dart:collection';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/file_access.dart';

class _EmbeddedCoverCacheEntry {
  final String previewPath;
  final int? sourceModTimeMillis;

  const _EmbeddedCoverCacheEntry({
    required this.previewPath,
    this.sourceModTimeMillis,
  });
}

/// Shared resolver for embedded cover previews from downloaded/local files.
/// It keeps a bounded in-memory cache and only refreshes extraction
/// when the source file changed.
class DownloadedEmbeddedCoverResolver {
  static const int _maxCacheEntries = 160;
  static const int _minModCheckIntervalMs = 1200;
  static const int _minPreviewExistsCheckIntervalMs = 2200;

  static final LinkedHashMap<String, _EmbeddedCoverCacheEntry> _cache =
      LinkedHashMap<String, _EmbeddedCoverCacheEntry>();
  static final Set<String> _pendingExtract = <String>{};
  static final Set<String> _pendingModCheck = <String>{};
  static final Set<String> _failedExtract = <String>{};
  static final Map<String, int> _lastModCheckMillis = <String, int>{};
  static final Map<String, int> _lastPreviewExistsCheckMillis =
      <String, int>{};

  static String cleanFilePath(String? filePath) {
    if (filePath == null) return '';
    if (filePath.startsWith('EXISTS:')) {
      return filePath.substring(7);
    }
    return filePath;
  }

  static Future<int?> readFileModTimeMillis(String? filePath) async {
    final cleanPath = cleanFilePath(filePath);
    if (cleanPath.isEmpty) return null;

    if (isContentUri(cleanPath)) {
      try {
        final modTimes = await PlatformBridge.getSafFileModTimes([cleanPath]);
        return modTimes[cleanPath];
      } catch (_) {
        return null;
      }
    }

    try {
      final stat = await File(cleanPath).stat();
      return stat.modified.millisecondsSinceEpoch;
    } catch (_) {
      return null;
    }
  }

  static String? resolve(String? filePath, {VoidCallback? onChanged}) {
    final cleanPath = cleanFilePath(filePath);
    if (cleanPath.isEmpty) return null;

    final cached = _cache[cleanPath];
    if (cached != null) {
      final now = DateTime.now().millisecondsSinceEpoch;
      final lastPreviewCheck = _lastPreviewExistsCheckMillis[cleanPath] ?? 0;
      final shouldVerifyExists =
          now - lastPreviewCheck >= _minPreviewExistsCheckIntervalMs;

      if (!shouldVerifyExists || File(cached.previewPath).existsSync()) {
        if (shouldVerifyExists) {
          _lastPreviewExistsCheckMillis[cleanPath] = now;
        }
        _touch(cleanPath, cached);
        _scheduleModCheck(cleanPath, onChanged: onChanged);
        return cached.previewPath;
      }
      _cache.remove(cleanPath);
      _lastPreviewExistsCheckMillis.remove(cleanPath);
      _cleanupTempCoverPathSync(cached.previewPath);
    }

    _ensureCover(cleanPath, onChanged: onChanged);
    return null;
  }

  static Future<void> scheduleRefreshForPath(
    String? filePath, {
    int? beforeModTime,
    bool force = false,
    VoidCallback? onChanged,
  }) async {
    final cleanPath = cleanFilePath(filePath);
    if (cleanPath.isEmpty) return;

    if (!force) {
      if (beforeModTime == null) return;
      final afterModTime = await readFileModTimeMillis(cleanPath);
      if (afterModTime != null && afterModTime == beforeModTime) {
        return;
      }
    }

    _failedExtract.remove(cleanPath);
    _ensureCover(cleanPath, forceRefresh: true, onChanged: onChanged);
  }

  static void invalidate(String? filePath) {
    final cleanPath = cleanFilePath(filePath);
    if (cleanPath.isEmpty) return;

    final cached = _cache.remove(cleanPath);
    _pendingExtract.remove(cleanPath);
    _pendingModCheck.remove(cleanPath);
    _failedExtract.remove(cleanPath);
    _lastModCheckMillis.remove(cleanPath);
    _lastPreviewExistsCheckMillis.remove(cleanPath);
    if (cached != null) {
      _cleanupTempCoverPathSync(cached.previewPath);
    }
  }

  static void _touch(String cleanPath, _EmbeddedCoverCacheEntry entry) {
    _cache
      ..remove(cleanPath)
      ..[cleanPath] = entry;
  }

  static void _trimCacheIfNeeded() {
    while (_cache.length > _maxCacheEntries) {
      final oldestKey = _cache.keys.first;
      final removed = _cache.remove(oldestKey);
      if (removed != null) {
        _cleanupTempCoverPathSync(removed.previewPath);
      }
      _pendingExtract.remove(oldestKey);
      _pendingModCheck.remove(oldestKey);
      _failedExtract.remove(oldestKey);
      _lastModCheckMillis.remove(oldestKey);
      _lastPreviewExistsCheckMillis.remove(oldestKey);
    }
  }

  static void _scheduleModCheck(String cleanPath, {VoidCallback? onChanged}) {
    if (_pendingModCheck.contains(cleanPath)) return;

    final now = DateTime.now().millisecondsSinceEpoch;
    final lastCheck = _lastModCheckMillis[cleanPath] ?? 0;
    if (now - lastCheck < _minModCheckIntervalMs) return;
    _lastModCheckMillis[cleanPath] = now;

    _pendingModCheck.add(cleanPath);
    Future.microtask(() async {
      try {
        final cached = _cache[cleanPath];
        if (cached == null) return;

        final currentModTime = await readFileModTimeMillis(cleanPath);
        if (currentModTime != null &&
            cached.sourceModTimeMillis != null &&
            currentModTime != cached.sourceModTimeMillis) {
          _ensureCover(
            cleanPath,
            forceRefresh: true,
            knownModTime: currentModTime,
            onChanged: onChanged,
          );
        }
      } finally {
        _pendingModCheck.remove(cleanPath);
      }
    });
  }

  static void _ensureCover(
    String cleanPath, {
    bool forceRefresh = false,
    int? knownModTime,
    VoidCallback? onChanged,
  }) {
    if (cleanPath.isEmpty) return;
    if (_pendingExtract.contains(cleanPath)) return;
    if (!forceRefresh && _cache.containsKey(cleanPath)) return;
    if (!forceRefresh && _failedExtract.contains(cleanPath)) return;

    _pendingExtract.add(cleanPath);
    Future.microtask(() async {
      String? outputPath;
      try {
        final modTime = knownModTime ?? await readFileModTimeMillis(cleanPath);
        final tempDir = await Directory.systemTemp.createTemp(
          'download_cover_preview_',
        );
        outputPath =
            '${tempDir.path}${Platform.pathSeparator}cover_preview.jpg';
        final result = await PlatformBridge.extractCoverToFile(
          cleanPath,
          outputPath,
        );

        final hasCover =
            result['error'] == null && await File(outputPath).exists();
        if (!hasCover) {
          _failedExtract.add(cleanPath);
          _cleanupTempCoverPathSync(outputPath);
          return;
        }

        final previous = _cache[cleanPath];
        final next = _EmbeddedCoverCacheEntry(
          previewPath: outputPath,
          sourceModTimeMillis: modTime,
        );
        _touch(cleanPath, next);
        _failedExtract.remove(cleanPath);
        _lastPreviewExistsCheckMillis[cleanPath] =
            DateTime.now().millisecondsSinceEpoch;
        _trimCacheIfNeeded();

        if (previous != null && previous.previewPath != outputPath) {
          _cleanupTempCoverPathSync(previous.previewPath);
        }
        onChanged?.call();
      } catch (_) {
        _failedExtract.add(cleanPath);
        _cleanupTempCoverPathSync(outputPath);
      } finally {
        _pendingExtract.remove(cleanPath);
      }
    });
  }

  static void _cleanupTempCoverPathSync(String? coverPath) {
    if (coverPath == null || coverPath.isEmpty) return;
    try {
      final file = File(coverPath);
      if (file.existsSync()) {
        file.deleteSync();
      }
      final parent = file.parent;
      if (parent.existsSync()) {
        parent.deleteSync(recursive: true);
      }
    } catch (_) {}
  }
}
