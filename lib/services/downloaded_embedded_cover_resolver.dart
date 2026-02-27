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
  static const int _maxCacheEntries = 180;

  static final LinkedHashMap<String, _EmbeddedCoverCacheEntry> _cache =
      LinkedHashMap<String, _EmbeddedCoverCacheEntry>();
  static final Set<String> _pendingExtract = <String>{};
  static final Set<String> _pendingRefresh = <String>{};
  static final Set<String> _pendingPreviewValidation = <String>{};
  static final Set<String> _failedExtract = <String>{};

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

    if (_pendingRefresh.remove(cleanPath)) {
      _ensureCover(cleanPath, forceRefresh: true, onChanged: onChanged);
    }

    final cached = _cache[cleanPath];
    if (cached != null) {
      _touch(cleanPath, cached);
      _validateCachedPreviewAsync(cleanPath, cached, onChanged: onChanged);
      return cached.previewPath;
    }

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

    _pendingRefresh.add(cleanPath);
    _failedExtract.remove(cleanPath);
    onChanged?.call();
  }

  static void invalidate(String? filePath) {
    final cleanPath = cleanFilePath(filePath);
    if (cleanPath.isEmpty) return;

    final cached = _cache.remove(cleanPath);
    _pendingExtract.remove(cleanPath);
    _pendingRefresh.remove(cleanPath);
    _pendingPreviewValidation.remove(cleanPath);
    _failedExtract.remove(cleanPath);
    if (cached != null) {
      _cleanupTempCoverPathSync(cached.previewPath);
    }
  }

  static void invalidatePathsNotIn(Set<String> validCleanPaths) {
    if (validCleanPaths.isEmpty) {
      final keys = _cache.keys.toList(growable: false);
      for (final key in keys) {
        invalidate(key);
      }
      return;
    }

    final staleKeys = _cache.keys
        .where((path) => !validCleanPaths.contains(path))
        .toList(growable: false);
    for (final key in staleKeys) {
      invalidate(key);
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
      _pendingRefresh.remove(oldestKey);
      _pendingPreviewValidation.remove(oldestKey);
      _failedExtract.remove(oldestKey);
    }
  }

  static void _validateCachedPreviewAsync(
    String cleanPath,
    _EmbeddedCoverCacheEntry entry, {
    VoidCallback? onChanged,
  }) {
    if (_pendingPreviewValidation.contains(cleanPath)) return;
    _pendingPreviewValidation.add(cleanPath);
    Future.microtask(() async {
      try {
        final exists = await fileExists(entry.previewPath);
        if (!exists) {
          final latest = _cache[cleanPath];
          if (latest != null && latest.previewPath == entry.previewPath) {
            _cache.remove(cleanPath);
            _failedExtract.remove(cleanPath);
            onChanged?.call();
          }
          _cleanupTempCoverPathSync(entry.previewPath);
        }
      } finally {
        _pendingPreviewValidation.remove(cleanPath);
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
