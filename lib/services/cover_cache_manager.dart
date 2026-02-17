import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Persistent cache manager for album/track cover images.
/// 
/// Unlike the default cache manager which stores in temp directory
/// (can be cleared by system anytime), this stores in app support
/// directory which persists across app restarts.
class CoverCacheManager {
  static const String _cacheKey = 'coverImageCache';
  static const int _maxCacheObjects = 1000;
  static const Duration _maxCacheAge = Duration(days: 365);

  static CacheManager? _instance;
  static bool _initialized = false;
  static String? _cachePath;

  static CacheManager get instance {
    if (!_initialized || _instance == null) {
      // Fallback to default cache manager if not initialized
      debugPrint('CoverCacheManager: Not initialized, using DefaultCacheManager');
      return DefaultCacheManager();
    }
    return _instance!;
  }

  static bool get isInitialized => _initialized && _instance != null;

  static Future<void> initialize() async {
    if (_initialized) return;

    try {
      final appDir = await getApplicationSupportDirectory();
      _cachePath = p.join(appDir.path, 'cover_cache');
      
      // Ensure cache directory exists
      await Directory(_cachePath!).create(recursive: true);
      
      debugPrint('CoverCacheManager: Initializing at $_cachePath');

      _instance = _createManager(_cachePath!);
      
      _initialized = true;
      debugPrint('CoverCacheManager: Initialized successfully');
    } catch (e) {
      debugPrint('CoverCacheManager: Failed to initialize: $e');
      // Will fallback to DefaultCacheManager
    }
  }

  static Future<void> clearCache() async {
    if (!_initialized || _instance == null || _cachePath == null) {
      await initialize();
    }

    final instance = _instance;
    final cachePath = _cachePath;

    if (instance == null || cachePath == null) return;

    // Ask cache manager to clear indexed entries first.
    try {
      await instance.emptyCache();
    } catch (e) {
      debugPrint('CoverCacheManager: emptyCache failed, fallback to wipe: $e');
    }

    // Then wipe the directory to remove orphaned files/metadata leftovers.
    await _wipeDirectory(cachePath);

    // Clear in-memory image cache so cleared covers are not retained in RAM.
    final imageCache = PaintingBinding.instance.imageCache;
    imageCache.clear();
    imageCache.clearLiveImages();

    // Reset manager memory/index state after on-disk wipe.
    instance.store.emptyMemoryCache();
    _instance = _createManager(cachePath);
    _initialized = true;
  }

  static Future<CacheStats> getStats() async {
    if (_cachePath == null) {
      try {
        final appDir = await getApplicationSupportDirectory();
        _cachePath = p.join(appDir.path, 'cover_cache');
      } catch (_) {
        return const CacheStats(fileCount: 0, totalSizeBytes: 0);
      }
    }

    if (_cachePath == null) {
      return const CacheStats(fileCount: 0, totalSizeBytes: 0);
    }

    final cacheDir = Directory(_cachePath!);
    
    if (!await cacheDir.exists()) {
      return const CacheStats(fileCount: 0, totalSizeBytes: 0);
    }

    int fileCount = 0;
    int totalSize = 0;

    try {
      await for (final entity in cacheDir.list(recursive: true)) {
        if (entity is File) {
          fileCount++;
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('CoverCacheManager: Error getting stats: $e');
    }

    return CacheStats(fileCount: fileCount, totalSizeBytes: totalSize);
  }

  static CacheManager _createManager(String cachePath) {
    return CacheManager(
      Config(
        _cacheKey,
        stalePeriod: _maxCacheAge,
        maxNrOfCacheObjects: _maxCacheObjects,
        // Use path only (not databaseName) to store database in persistent directory
        repo: JsonCacheInfoRepository(path: cachePath),
        fileSystem: IOFileSystem(cachePath),
        fileService: HttpFileService(),
      ),
    );
  }

  static Future<void> _wipeDirectory(String path) async {
    final directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
      return;
    }

    try {
      final entities = <FileSystemEntity>[];
      await for (final entity in directory.list(followLinks: false)) {
        entities.add(entity);
      }

      for (final entity in entities) {
        try {
          await entity.delete(recursive: true);
        } catch (_) {}
      }
    } catch (_) {}

    try {
      await directory.create(recursive: true);
    } catch (_) {}
  }
}

class CacheStats {
  final int fileCount;
  final int totalSizeBytes;

  const CacheStats({
    required this.fileCount,
    required this.totalSizeBytes,
  });

  String get formattedSize {
    if (totalSizeBytes < 1024) {
      return '$totalSizeBytes B';
    } else if (totalSizeBytes < 1024 * 1024) {
      return '${(totalSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (totalSizeBytes < 1024 * 1024 * 1024) {
      return '${(totalSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(totalSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(2)} GB';
    }
  }
}
