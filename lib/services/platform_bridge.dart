import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:spotiflac_android/services/download_request_payload.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('PlatformBridge');

class PlatformBridge {
  static const _channel = MethodChannel('com.zarz.spotiflac/backend');
  static const _downloadProgressEvents = EventChannel(
    'com.zarz.spotiflac/download_progress_stream',
  );
  static const _libraryScanProgressEvents = EventChannel(
    'com.zarz.spotiflac/library_scan_progress_stream',
  );

  static bool get supportsCoreBackend => Platform.isAndroid || Platform.isIOS;

  static bool get supportsExtensionSystem =>
      Platform.isAndroid || Platform.isIOS;

  static Future<Map<String, dynamic>> checkAvailability(
    String spotifyId,
    String isrc,
  ) async {
    _log.d('checkAvailability: $spotifyId (ISRC: $isrc)');
    final result = await _channel.invokeMethod('checkAvailability', {
      'spotify_id': spotifyId,
      'isrc': isrc,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> _invokeDownloadMethod(
    String method,
    DownloadRequestPayload payload,
  ) async {
    final request = jsonEncode(payload.toJson());
    final result = await _channel.invokeMethod(method, request);
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> downloadByStrategy({
    required DownloadRequestPayload payload,
    bool? useExtensions,
    bool? useFallback,
  }) async {
    final routedPayload = payload.withStrategy(
      useExtensions: useExtensions,
      useFallback: useFallback,
    );
    _log.i(
      'downloadByStrategy: "${payload.trackName}" by ${payload.artistName} '
      '(service: ${payload.service}, ext: ${routedPayload.useExtensions}, fallback: ${routedPayload.useFallback})',
    );
    final response = await _invokeDownloadMethod(
      'downloadByStrategy',
      routedPayload,
    );
    if (response['success'] == true) {
      final service = response['service'] ?? payload.service;
      final filePath = response['file_path'] ?? '';
      final bitDepth = response['actual_bit_depth'] as num?;
      final sampleRate = response['actual_sample_rate'] as num?;
      final qualityStr = bitDepth != null && sampleRate != null
          ? ' ($bitDepth-bit/${(sampleRate / 1000).toStringAsFixed(1)}kHz)'
          : '';
      _log.i('Download success via $service$qualityStr: $filePath');
    } else {
      final error = response['error'] ?? 'Unknown error';
      final errorType = response['error_type'] ?? '';
      _log.e('Download failed: $error (type: $errorType)');
    }
    return response;
  }

  static Future<Map<String, dynamic>> getDownloadProgress() async {
    final result = await _channel.invokeMethod('getDownloadProgress');
    return _decodeMapResult(result);
  }

  static Future<Map<String, dynamic>> getAllDownloadProgress() async {
    final result = await _channel.invokeMethod('getAllDownloadProgress');
    return _decodeMapResult(result);
  }

  static Stream<Map<String, dynamic>> downloadProgressStream() {
    return _downloadProgressEvents.receiveBroadcastStream().map(
      _decodeMapResult,
    );
  }

  static Future<void> exitApp() async {
    await _channel.invokeMethod('exitApp');
  }

  static Future<void> initItemProgress(String itemId) async {
    await _channel.invokeMethod('initItemProgress', {'item_id': itemId});
  }

  static Future<void> finishItemProgress(String itemId) async {
    await _channel.invokeMethod('finishItemProgress', {'item_id': itemId});
  }

  static Future<void> clearItemProgress(String itemId) async {
    await _channel.invokeMethod('clearItemProgress', {'item_id': itemId});
  }

  static Future<void> cancelDownload(String itemId) async {
    await _channel.invokeMethod('cancelDownload', {'item_id': itemId});
  }

  static Future<void> setDownloadDirectory(String path) async {
    await _channel.invokeMethod('setDownloadDirectory', {'path': path});
  }

  static Future<void> setNetworkCompatibilityOptions({
    required bool allowHttp,
    required bool insecureTls,
  }) async {
    await _channel.invokeMethod('setNetworkCompatibilityOptions', {
      'allow_http': allowHttp,
      'insecure_tls': insecureTls,
    });
  }

  static Future<Map<String, dynamic>> checkDuplicate(
    String outputDir,
    String isrc,
  ) async {
    final result = await _channel.invokeMethod('checkDuplicate', {
      'output_dir': outputDir,
      'isrc': isrc,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<String> buildFilename(
    String template,
    Map<String, dynamic> metadata,
  ) async {
    final result = await _channel.invokeMethod('buildFilename', {
      'template': template,
      'metadata': jsonEncode(metadata),
    });
    return result as String;
  }

  static Future<String> sanitizeFilename(String filename) async {
    final result = await _channel.invokeMethod('sanitizeFilename', {
      'filename': filename,
    });
    return result as String;
  }

  static Future<Map<String, dynamic>?> pickSafTree() async {
    final result = await _channel.invokeMethod('pickSafTree');
    if (result == null) return null;
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<bool> safExists(String uri) async {
    final result = await _channel.invokeMethod('safExists', {'uri': uri});
    return result as bool;
  }

  static Future<bool> safDelete(String uri) async {
    final result = await _channel.invokeMethod('safDelete', {'uri': uri});
    return result as bool;
  }

  static Future<Map<String, dynamic>> safStat(String uri) async {
    final result = await _channel.invokeMethod('safStat', {'uri': uri});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> resolveSafFile({
    required String treeUri,
    required String fileName,
    String relativeDir = '',
  }) async {
    final result = await _channel.invokeMethod('resolveSafFile', {
      'tree_uri': treeUri,
      'relative_dir': relativeDir,
      'file_name': fileName,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<String?> copyContentUriToTemp(String uri) async {
    final result = await _channel.invokeMethod('safCopyToTemp', {'uri': uri});
    return result as String?;
  }

  static Future<bool> replaceContentUriFromPath(
    String uri,
    String srcPath,
  ) async {
    final result = await _channel.invokeMethod('safReplaceFromPath', {
      'uri': uri,
      'src_path': srcPath,
    });
    return result as bool;
  }

  static Future<String?> createSafFileFromPath({
    required String treeUri,
    required String relativeDir,
    required String fileName,
    required String mimeType,
    required String srcPath,
  }) async {
    final result = await _channel.invokeMethod('safCreateFromPath', {
      'tree_uri': treeUri,
      'relative_dir': relativeDir,
      'file_name': fileName,
      'mime_type': mimeType,
      'src_path': srcPath,
    });
    return result as String?;
  }

  static Future<void> openContentUri(String uri, {String mimeType = ''}) async {
    await _channel.invokeMethod('openContentUri', {
      'uri': uri,
      'mime_type': mimeType,
    });
  }

  static Future<bool> shareContentUri(String uri, {String title = ''}) async {
    final result = await _channel.invokeMethod('shareContentUri', {
      'uri': uri,
      'title': title,
    });
    return result as bool? ?? false;
  }

  static Future<bool> shareMultipleContentUris(
    List<String> uris, {
    String title = '',
  }) async {
    final result = await _channel.invokeMethod('shareMultipleContentUris', {
      'uris': uris,
      'title': title,
    });
    return result as bool? ?? false;
  }

  static Future<Map<String, dynamic>> fetchLyrics(
    String spotifyId,
    String trackName,
    String artistName, {
    int durationMs = 0,
  }) async {
    final result = await _channel.invokeMethod('fetchLyrics', {
      'spotify_id': spotifyId,
      'track_name': trackName,
      'artist_name': artistName,
      'duration_ms': durationMs,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<String> getLyricsLRC(
    String spotifyId,
    String trackName,
    String artistName, {
    String? filePath,
    int durationMs = 0,
  }) async {
    final result = await _channel.invokeMethod('getLyricsLRC', {
      'spotify_id': spotifyId,
      'track_name': trackName,
      'artist_name': artistName,
      'file_path': filePath ?? '',
      'duration_ms': durationMs,
    });
    return result as String;
  }

  static Future<Map<String, dynamic>> getLyricsLRCWithSource(
    String spotifyId,
    String trackName,
    String artistName, {
    String? filePath,
    int durationMs = 0,
  }) async {
    final result = await _channel.invokeMethod('getLyricsLRCWithSource', {
      'spotify_id': spotifyId,
      'track_name': trackName,
      'artist_name': artistName,
      'file_path': filePath ?? '',
      'duration_ms': durationMs,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> embedLyricsToFile(
    String filePath,
    String lyrics,
  ) async {
    final result = await _channel.invokeMethod('embedLyricsToFile', {
      'file_path': filePath,
      'lyrics': lyrics,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<void> cleanupConnections() async {
    await _channel.invokeMethod('cleanupConnections');
  }

  static Future<Map<String, dynamic>> downloadCoverToFile(
    String coverUrl,
    String outputPath, {
    bool maxQuality = true,
  }) async {
    final result = await _channel.invokeMethod('downloadCoverToFile', {
      'cover_url': coverUrl,
      'output_path': outputPath,
      'max_quality': maxQuality,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> extractCoverToFile(
    String audioPath,
    String outputPath,
  ) async {
    final result = await _channel.invokeMethod('extractCoverToFile', {
      'audio_path': audioPath,
      'output_path': outputPath,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> fetchAndSaveLyrics({
    required String trackName,
    required String artistName,
    required String spotifyId,
    required int durationMs,
    required String outputPath,
  }) async {
    final result = await _channel.invokeMethod('fetchAndSaveLyrics', {
      'track_name': trackName,
      'artist_name': artistName,
      'spotify_id': spotifyId,
      'duration_ms': durationMs,
      'output_path': outputPath,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  /// Sets the lyrics provider order. Providers not in the list are disabled.
  static Future<void> setLyricsProviders(List<String> providers) async {
    final providersJSON = jsonEncode(providers);
    await _channel.invokeMethod('setLyricsProviders', {
      'providers_json': providersJSON,
    });
  }

  /// Returns the current lyrics provider order.
  static Future<List<String>> getLyricsProviders() async {
    final result = await _channel.invokeMethod('getLyricsProviders');
    final List<dynamic> decoded = jsonDecode(result as String) as List<dynamic>;
    return decoded.cast<String>();
  }

  /// Returns metadata about all available lyrics providers.
  static Future<List<Map<String, dynamic>>>
  getAvailableLyricsProviders() async {
    final result = await _channel.invokeMethod('getAvailableLyricsProviders');
    final List<dynamic> decoded = jsonDecode(result as String) as List<dynamic>;
    return decoded.cast<Map<String, dynamic>>();
  }

  /// Sets advanced lyrics fetch options used by provider-specific integrations.
  static Future<void> setLyricsFetchOptions(
    Map<String, dynamic> options,
  ) async {
    final optionsJSON = jsonEncode(options);
    await _channel.invokeMethod('setLyricsFetchOptions', {
      'options_json': optionsJSON,
    });
  }

  /// Returns current advanced lyrics fetch options.
  static Future<Map<String, dynamic>> getLyricsFetchOptions() async {
    final result = await _channel.invokeMethod('getLyricsFetchOptions');
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> reEnrichFile(
    Map<String, dynamic> request,
  ) async {
    final requestJSON = jsonEncode(request);
    final result = await _channel.invokeMethod('reEnrichFile', {
      'request_json': requestJSON,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> readFileMetadata(String filePath) async {
    final result = await _channel.invokeMethod('readFileMetadata', {
      'file_path': filePath,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> editFileMetadata(
    String filePath,
    Map<String, String> metadata,
  ) async {
    final metadataJSON = jsonEncode(metadata);
    final result = await _channel.invokeMethod('editFileMetadata', {
      'file_path': filePath,
      'metadata_json': metadataJSON,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<bool> writeTempToSaf(String tempPath, String safUri) async {
    final result = await _channel.invokeMethod('writeTempToSaf', {
      'temp_path': tempPath,
      'saf_uri': safUri,
    });
    final map = jsonDecode(result as String) as Map<String, dynamic>;
    return map['success'] == true;
  }

  static Future<void> startDownloadService({
    String trackName = '',
    String artistName = '',
    int queueCount = 0,
  }) async {
    await _channel.invokeMethod('startDownloadService', {
      'track_name': trackName,
      'artist_name': artistName,
      'queue_count': queueCount,
    });
  }

  static Future<void> stopDownloadService() async {
    await _channel.invokeMethod('stopDownloadService');
  }

  static Future<void> updateDownloadServiceProgress({
    required String trackName,
    required String artistName,
    required int progress,
    required int total,
    required int queueCount,
  }) async {
    await _channel.invokeMethod('updateDownloadServiceProgress', {
      'track_name': trackName,
      'artist_name': artistName,
      'progress': progress,
      'total': total,
      'queue_count': queueCount,
    });
  }

  static Future<bool> isDownloadServiceRunning() async {
    final result = await _channel.invokeMethod('isDownloadServiceRunning');
    return result as bool;
  }

  static Future<void> preWarmTrackCache(
    List<Map<String, String>> tracks,
  ) async {
    final tracksJson = jsonEncode(tracks);
    await _channel.invokeMethod('preWarmTrackCache', {'tracks': tracksJson});
  }

  static Future<int> getTrackCacheSize() async {
    final result = await _channel.invokeMethod('getTrackCacheSize');
    return result as int;
  }

  static Future<void> clearTrackCache() async {
    await _channel.invokeMethod('clearTrackCache');
  }

  static Future<Map<String, dynamic>> searchDeezerAll(
    String query, {
    int trackLimit = 15,
    int artistLimit = 2,
    String? filter,
  }) async {
    final result = await _channel.invokeMethod('searchDeezerAll', {
      'query': query,
      'track_limit': trackLimit,
      'artist_limit': artistLimit,
      'filter': filter ?? '',
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> searchTidalAll(
    String query, {
    int trackLimit = 15,
    int artistLimit = 2,
    String? filter,
  }) async {
    final result = await _channel.invokeMethod('searchTidalAll', {
      'query': query,
      'track_limit': trackLimit,
      'artist_limit': artistLimit,
      'filter': filter ?? '',
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> searchQobuzAll(
    String query, {
    int trackLimit = 15,
    int artistLimit = 2,
    String? filter,
  }) async {
    final result = await _channel.invokeMethod('searchQobuzAll', {
      'query': query,
      'track_limit': trackLimit,
      'artist_limit': artistLimit,
      'filter': filter ?? '',
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDeezerRelatedArtists(
    String artistId, {
    int limit = 12,
  }) async {
    final result = await _channel.invokeMethod('getDeezerRelatedArtists', {
      'artist_id': artistId,
      'limit': limit,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDeezerMetadata(
    String resourceType,
    String resourceId,
  ) async {
    final result = await _channel.invokeMethod('getDeezerMetadata', {
      'resource_type': resourceType,
      'resource_id': resourceId,
    });
    if (result == null) {
      throw Exception(
        'getDeezerMetadata returned null for $resourceType:$resourceId',
      );
    }
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> parseDeezerUrl(String url) async {
    final result = await _channel.invokeMethod('parseDeezerUrl', {'url': url});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getQobuzMetadata(
    String resourceType,
    String resourceId,
  ) async {
    final result = await _channel.invokeMethod('getQobuzMetadata', {
      'resource_type': resourceType,
      'resource_id': resourceId,
    });
    if (result == null) {
      throw Exception(
        'getQobuzMetadata returned null for $resourceType:$resourceId',
      );
    }
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> parseQobuzUrl(String url) async {
    final result = await _channel.invokeMethod('parseQobuzUrl', {'url': url});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> parseTidalUrl(String url) async {
    final result = await _channel.invokeMethod('parseTidalUrl', {'url': url});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getTidalMetadata(
    String resourceType,
    String resourceId,
  ) async {
    final result = await _channel.invokeMethod('getTidalMetadata', {
      'resource_type': resourceType,
      'resource_id': resourceId,
    });
    if (result == null) {
      throw Exception(
        'getTidalMetadata returned null for $resourceType:$resourceId',
      );
    }
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> convertTidalToSpotifyDeezer(
    String tidalUrl,
  ) async {
    final result = await _channel.invokeMethod('convertTidalToSpotifyDeezer', {
      'url': tidalUrl,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> searchDeezerByISRC(String isrc) async {
    final result = await _channel.invokeMethod('searchDeezerByISRC', {
      'isrc': isrc,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, String>?> getDeezerExtendedMetadata(
    String trackId,
  ) async {
    try {
      final result = await _channel.invokeMethod('getDeezerExtendedMetadata', {
        'track_id': trackId,
      });
      if (result == null) return null;
      final data = jsonDecode(result as String) as Map<String, dynamic>;
      return {
        'genre': data['genre'] as String? ?? '',
        'label': data['label'] as String? ?? '',
        'copyright': data['copyright'] as String? ?? '',
      };
    } catch (e) {
      _log.w('Failed to get Deezer extended metadata for $trackId: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> convertSpotifyToDeezer(
    String resourceType,
    String spotifyId,
  ) async {
    final result = await _channel.invokeMethod('convertSpotifyToDeezer', {
      'resource_type': resourceType,
      'spotify_id': spotifyId,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getGoLogs() async {
    final result = await _channel.invokeMethod('getLogs');
    final logs = jsonDecode(result as String) as List<dynamic>;
    return logs.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<Map<String, dynamic>> getGoLogsSince(int index) async {
    final result = await _channel.invokeMethod('getLogsSince', {
      'index': index,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<void> clearGoLogs() async {
    await _channel.invokeMethod('clearLogs');
  }

  static Future<int> getGoLogCount() async {
    final result = await _channel.invokeMethod('getLogCount');
    return result as int;
  }

  static Future<void> setGoLoggingEnabled(bool enabled) async {
    await _channel.invokeMethod('setLoggingEnabled', {'enabled': enabled});
  }

  static Future<void> initExtensionSystem(
    String extensionsDir,
    String dataDir,
  ) async {
    _log.d('initExtensionSystem: $extensionsDir, $dataDir');
    await _channel.invokeMethod('initExtensionSystem', {
      'extensions_dir': extensionsDir,
      'data_dir': dataDir,
    });
  }

  static Future<Map<String, dynamic>> loadExtensionsFromDir(
    String dirPath,
  ) async {
    _log.d('loadExtensionsFromDir: $dirPath');
    final result = await _channel.invokeMethod('loadExtensionsFromDir', {
      'dir_path': dirPath,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> loadExtensionFromPath(
    String filePath,
  ) async {
    _log.d('loadExtensionFromPath: $filePath');
    final result = await _channel.invokeMethod('loadExtensionFromPath', {
      'file_path': filePath,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<void> unloadExtension(String extensionId) async {
    _log.d('unloadExtension: $extensionId');
    await _channel.invokeMethod('unloadExtension', {
      'extension_id': extensionId,
    });
  }

  static Future<void> removeExtension(String extensionId) async {
    _log.d('removeExtension: $extensionId');
    await _channel.invokeMethod('removeExtension', {
      'extension_id': extensionId,
    });
  }

  static Future<Map<String, dynamic>> upgradeExtension(String filePath) async {
    _log.d('upgradeExtension: $filePath');
    final result = await _channel.invokeMethod('upgradeExtension', {
      'file_path': filePath,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> checkExtensionUpgrade(
    String filePath,
  ) async {
    _log.d('checkExtensionUpgrade: $filePath');
    final result = await _channel.invokeMethod('checkExtensionUpgrade', {
      'file_path': filePath,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getInstalledExtensions() async {
    final result = await _channel.invokeMethod('getInstalledExtensions');
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<void> setExtensionEnabled(
    String extensionId,
    bool enabled,
  ) async {
    _log.d('setExtensionEnabled: $extensionId = $enabled');
    await _channel.invokeMethod('setExtensionEnabled', {
      'extension_id': extensionId,
      'enabled': enabled,
    });
  }

  static Future<void> setProviderPriority(List<String> providerIds) async {
    _log.d('setProviderPriority: $providerIds');
    await _channel.invokeMethod('setProviderPriority', {
      'priority': jsonEncode(providerIds),
    });
  }

  static Future<List<String>> getProviderPriority() async {
    final result = await _channel.invokeMethod('getProviderPriority');
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as String).toList();
  }

  static Future<void> setMetadataProviderPriority(
    List<String> providerIds,
  ) async {
    _log.d('setMetadataProviderPriority: $providerIds');
    await _channel.invokeMethod('setMetadataProviderPriority', {
      'priority': jsonEncode(providerIds),
    });
  }

  static Future<List<String>> getMetadataProviderPriority() async {
    final result = await _channel.invokeMethod('getMetadataProviderPriority');
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as String).toList();
  }

  static Future<Map<String, dynamic>> getExtensionSettings(
    String extensionId,
  ) async {
    final result = await _channel.invokeMethod('getExtensionSettings', {
      'extension_id': extensionId,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<void> setExtensionSettings(
    String extensionId,
    Map<String, dynamic> settings,
  ) async {
    _log.d('setExtensionSettings: $extensionId');
    await _channel.invokeMethod('setExtensionSettings', {
      'extension_id': extensionId,
      'settings': jsonEncode(settings),
    });
  }

  static Future<Map<String, dynamic>> invokeExtensionAction(
    String extensionId,
    String actionName,
  ) async {
    _log.d('invokeExtensionAction: $extensionId.$actionName');
    final result = await _channel.invokeMethod('invokeExtensionAction', {
      'extension_id': extensionId,
      'action': actionName,
    });
    if (result == null || (result as String).isEmpty) {
      return {'success': true};
    }
    return jsonDecode(result) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> searchTracksWithExtensions(
    String query, {
    int limit = 20,
  }) async {
    _log.d('searchTracksWithExtensions: "$query"');
    final result = await _channel.invokeMethod('searchTracksWithExtensions', {
      'query': query,
      'limit': limit,
    });
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<List<Map<String, dynamic>>> searchTracksWithMetadataProviders(
    String query, {
    int limit = 20,
    bool includeExtensions = true,
  }) async {
    _log.d(
      'searchTracksWithMetadataProviders: "$query", includeExtensions=$includeExtensions',
    );
    final result = await _channel.invokeMethod(
      'searchTracksWithMetadataProviders',
      {'query': query, 'limit': limit, 'include_extensions': includeExtensions},
    );
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<void> cleanupExtensions() async {
    _log.d('cleanupExtensions');
    await _channel.invokeMethod('cleanupExtensions');
  }

  static Future<Map<String, dynamic>?> getExtensionPendingAuth(
    String extensionId,
  ) async {
    final result = await _channel.invokeMethod('getExtensionPendingAuth', {
      'extension_id': extensionId,
    });
    if (result == null) return null;
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<void> setExtensionAuthCode(
    String extensionId,
    String authCode,
  ) async {
    _log.d('setExtensionAuthCode: $extensionId');
    await _channel.invokeMethod('setExtensionAuthCode', {
      'extension_id': extensionId,
      'auth_code': authCode,
    });
  }

  static Future<void> setExtensionTokens(
    String extensionId, {
    required String accessToken,
    String? refreshToken,
    int? expiresIn,
  }) async {
    _log.d('setExtensionTokens: $extensionId');
    await _channel.invokeMethod('setExtensionTokens', {
      'extension_id': extensionId,
      'access_token': accessToken,
      'refresh_token': refreshToken ?? '',
      'expires_in': expiresIn ?? 0,
    });
  }

  static Future<void> clearExtensionPendingAuth(String extensionId) async {
    await _channel.invokeMethod('clearExtensionPendingAuth', {
      'extension_id': extensionId,
    });
  }

  static Future<bool> isExtensionAuthenticated(String extensionId) async {
    final result = await _channel.invokeMethod('isExtensionAuthenticated', {
      'extension_id': extensionId,
    });
    return result as bool;
  }

  static Future<List<Map<String, dynamic>>> getAllPendingAuthRequests() async {
    final result = await _channel.invokeMethod('getAllPendingAuthRequests');
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<Map<String, dynamic>?> getPendingFFmpegCommand(
    String commandId,
  ) async {
    final result = await _channel.invokeMethod('getPendingFFmpegCommand', {
      'command_id': commandId,
    });
    if (result == null) return null;
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<void> setFFmpegCommandResult(
    String commandId, {
    required bool success,
    String output = '',
    String error = '',
  }) async {
    await _channel.invokeMethod('setFFmpegCommandResult', {
      'command_id': commandId,
      'success': success,
      'output': output,
      'error': error,
    });
  }

  static Future<List<Map<String, dynamic>>>
  getAllPendingFFmpegCommands() async {
    final result = await _channel.invokeMethod('getAllPendingFFmpegCommands');
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<List<Map<String, dynamic>>> customSearchWithExtension(
    String extensionId,
    String query, {
    Map<String, dynamic>? options,
  }) async {
    final result = await _channel.invokeMethod('customSearchWithExtension', {
      'extension_id': extensionId,
      'query': query,
      'options': options != null ? jsonEncode(options) : '',
    });
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<List<Map<String, dynamic>>> getSearchProviders() async {
    final result = await _channel.invokeMethod('getSearchProviders');
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<Map<String, dynamic>?> handleURLWithExtension(
    String url,
  ) async {
    try {
      final result = await _channel.invokeMethod('handleURLWithExtension', {
        'url': url,
      });
      if (result == null || result == '') return null;
      return jsonDecode(result as String) as Map<String, dynamic>;
    } catch (e) {
      return null;
    }
  }

  static Future<String?> findURLHandler(String url) async {
    final result = await _channel.invokeMethod('findURLHandler', {'url': url});
    if (result == null || result == '') return null;
    return result as String;
  }

  static Future<List<Map<String, dynamic>>> getURLHandlers() async {
    final result = await _channel.invokeMethod('getURLHandlers');
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<Map<String, dynamic>?> getAlbumWithExtension(
    String extensionId,
    String albumId,
  ) async {
    try {
      final result = await _channel.invokeMethod('getAlbumWithExtension', {
        'extension_id': extensionId,
        'album_id': albumId,
      });
      if (result == null || result == '') return null;
      return jsonDecode(result as String) as Map<String, dynamic>;
    } catch (e) {
      _log.e('getAlbumWithExtension failed: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getPlaylistWithExtension(
    String extensionId,
    String playlistId,
  ) async {
    try {
      final result = await _channel.invokeMethod('getPlaylistWithExtension', {
        'extension_id': extensionId,
        'playlist_id': playlistId,
      });
      if (result == null || result == '') return null;
      return jsonDecode(result as String) as Map<String, dynamic>;
    } catch (e) {
      _log.e('getPlaylistWithExtension failed: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getArtistWithExtension(
    String extensionId,
    String artistId,
  ) async {
    try {
      final result = await _channel.invokeMethod('getArtistWithExtension', {
        'extension_id': extensionId,
        'artist_id': artistId,
      });
      if (result == null || result == '') return null;
      return jsonDecode(result as String) as Map<String, dynamic>;
    } catch (e) {
      _log.e('getArtistWithExtension failed: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getExtensionHomeFeed(
    String extensionId,
  ) async {
    try {
      final result = await _channel.invokeMethod('getExtensionHomeFeed', {
        'extension_id': extensionId,
      });
      if (result == null || result == '') return null;
      return jsonDecode(result as String) as Map<String, dynamic>;
    } catch (e) {
      _log.e('getExtensionHomeFeed failed: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>?> getExtensionBrowseCategories(
    String extensionId,
  ) async {
    try {
      final result = await _channel.invokeMethod(
        'getExtensionBrowseCategories',
        {'extension_id': extensionId},
      );
      if (result == null || result == '') return null;
      return jsonDecode(result as String) as Map<String, dynamic>;
    } catch (e) {
      _log.e('getExtensionBrowseCategories failed: $e');
      return null;
    }
  }

  static Future<void> setLibraryCoverCacheDir(String cacheDir) async {
    _log.i('setLibraryCoverCacheDir: $cacheDir');
    await _channel.invokeMethod('setLibraryCoverCacheDir', {
      'cache_dir': cacheDir,
    });
  }

  static Future<List<Map<String, dynamic>>> scanLibraryFolder(
    String folderPath,
  ) async {
    _log.i('scanLibraryFolder: $folderPath');
    final result = await _channel.invokeMethod('scanLibraryFolder', {
      'folder_path': folderPath,
    });
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<Map<String, dynamic>> scanLibraryFolderIncremental(
    String folderPath,
    Map<String, int> existingFiles,
  ) async {
    _log.i(
      'scanLibraryFolderIncremental: $folderPath (${existingFiles.length} existing files)',
    );
    final result = await _channel.invokeMethod('scanLibraryFolderIncremental', {
      'folder_path': folderPath,
      'existing_files': jsonEncode(existingFiles),
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> scanLibraryFolderIncrementalFromSnapshot(
    String folderPath,
    String snapshotPath,
  ) async {
    final result = await _channel.invokeMethod(
      'scanLibraryFolderIncrementalFromSnapshot',
      {'folder_path': folderPath, 'snapshot_path': snapshotPath},
    );
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> scanSafTree(String treeUri) async {
    _log.i('scanSafTree: $treeUri');
    final result = await _channel.invokeMethod('scanSafTree', {
      'tree_uri': treeUri,
    });
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<Map<String, dynamic>> scanSafTreeIncremental(
    String treeUri,
    Map<String, int> existingFiles,
  ) async {
    _log.i(
      'scanSafTreeIncremental: $treeUri (${existingFiles.length} existing files)',
    );
    final result = await _channel.invokeMethod('scanSafTreeIncremental', {
      'tree_uri': treeUri,
      'existing_files': jsonEncode(existingFiles),
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> scanSafTreeIncrementalFromSnapshot(
    String treeUri,
    String snapshotPath,
  ) async {
    final result = await _channel.invokeMethod(
      'scanSafTreeIncrementalFromSnapshot',
      {'tree_uri': treeUri, 'snapshot_path': snapshotPath},
    );
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, int>> getSafFileModTimes(List<String> uris) async {
    final result = await _channel.invokeMethod('getSafFileModTimes', {
      'uris': jsonEncode(uris),
    });
    final map = jsonDecode(result as String) as Map<String, dynamic>;
    return map.map((key, value) => MapEntry(key, (value as num).toInt()));
  }

  static Future<Map<String, dynamic>> getLibraryScanProgress() async {
    final result = await _channel.invokeMethod('getLibraryScanProgress');
    return _decodeMapResult(result);
  }

  static Stream<Map<String, dynamic>> libraryScanProgressStream() {
    return _libraryScanProgressEvents.receiveBroadcastStream().map(
      _decodeMapResult,
    );
  }

  static Future<void> cancelLibraryScan() async {
    await _channel.invokeMethod('cancelLibraryScan');
  }

  static Map<String, dynamic> _decodeMapResult(dynamic result) {
    if (result is Map) {
      return Map<String, dynamic>.from(result);
    }
    if (result is String) {
      if (result.isEmpty) return const <String, dynamic>{};
      final decoded = jsonDecode(result);
      if (decoded is Map) {
        return Map<String, dynamic>.from(decoded);
      }
    }
    return const <String, dynamic>{};
  }

  // MARK: - iOS Security-Scoped Bookmark

  /// Create a security-scoped bookmark from a filesystem path picked by
  /// FilePicker on iOS. Must be called while the picker session is still active.
  /// Returns base64-encoded bookmark data, or null on failure.
  static Future<String?> createIosBookmarkFromPath(String path) async {
    try {
      final result = await _channel.invokeMethod('createIosBookmarkFromPath', {
        'path': path,
      });
      return result as String?;
    } catch (e) {
      _log.w('Failed to create iOS bookmark from path: $e');
      return null;
    }
  }

  /// Resolve a base64-encoded iOS security-scoped bookmark and start accessing
  /// the resource. Returns the resolved filesystem path.
  /// The resource stays accessed until [stopAccessingIosBookmark] is called.
  static Future<String?> startAccessingIosBookmark(String bookmark) async {
    try {
      final result = await _channel.invokeMethod('startAccessingIosBookmark', {
        'bookmark': bookmark,
      });
      return result as String?;
    } catch (e) {
      _log.w('Failed to start accessing iOS bookmark: $e');
      return null;
    }
  }

  /// Stop accessing the currently active iOS security-scoped resource.
  static Future<void> stopAccessingIosBookmark() async {
    try {
      await _channel.invokeMethod('stopAccessingIosBookmark');
    } catch (e) {
      _log.w('Failed to stop accessing iOS bookmark: $e');
    }
  }

  static Future<Map<String, dynamic>?> readAudioMetadata(
    String filePath,
  ) async {
    try {
      final result = await _channel.invokeMethod('readAudioMetadata', {
        'file_path': filePath,
      });
      if (result == null || result == '') return null;
      return jsonDecode(result as String) as Map<String, dynamic>;
    } catch (e) {
      _log.w('Failed to read audio metadata: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> runPostProcessing(
    String filePath, {
    Map<String, dynamic>? metadata,
  }) async {
    final result = await _channel.invokeMethod('runPostProcessing', {
      'file_path': filePath,
      'metadata': metadata != null ? jsonEncode(metadata) : '',
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> runPostProcessingV2(
    String filePath, {
    Map<String, dynamic>? metadata,
  }) async {
    final input = <String, dynamic>{};
    if (filePath.startsWith('content://')) {
      input['uri'] = filePath;
    } else {
      input['path'] = filePath;
    }
    final result = await _channel.invokeMethod('runPostProcessingV2', {
      'input': jsonEncode(input),
      'metadata': metadata != null ? jsonEncode(metadata) : '',
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getPostProcessingProviders() async {
    final result = await _channel.invokeMethod('getPostProcessingProviders');
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<void> initExtensionStore(String cacheDir) async {
    _log.d('initExtensionStore: $cacheDir');
    await _channel.invokeMethod('initExtensionStore', {'cache_dir': cacheDir});
  }

  static Future<void> setStoreRegistryUrl(String registryUrl) async {
    _log.d('setStoreRegistryUrl: $registryUrl');
    await _channel.invokeMethod('setStoreRegistryUrl', {
      'registry_url': registryUrl,
    });
  }

  static Future<String> getStoreRegistryUrl() async {
    _log.d('getStoreRegistryUrl');
    final result = await _channel.invokeMethod('getStoreRegistryUrl');
    return result as String? ?? '';
  }

  static Future<void> clearStoreRegistryUrl() async {
    _log.d('clearStoreRegistryUrl');
    await _channel.invokeMethod('clearStoreRegistryUrl');
  }

  static Future<List<Map<String, dynamic>>> getStoreExtensions({
    bool forceRefresh = false,
  }) async {
    _log.d('getStoreExtensions (forceRefresh: $forceRefresh)');
    final result = await _channel.invokeMethod('getStoreExtensions', {
      'force_refresh': forceRefresh,
    });
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<List<Map<String, dynamic>>> searchStoreExtensions(
    String query, {
    String? category,
  }) async {
    _log.d('searchStoreExtensions: "$query" (category: $category)');
    final result = await _channel.invokeMethod('searchStoreExtensions', {
      'query': query,
      'category': category ?? '',
    });
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<List<String>> getStoreCategories() async {
    final result = await _channel.invokeMethod('getStoreCategories');
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.cast<String>();
  }

  static Future<String> downloadStoreExtension(
    String extensionId,
    String destDir,
  ) async {
    _log.i('downloadStoreExtension: $extensionId to $destDir');
    final result = await _channel.invokeMethod('downloadStoreExtension', {
      'extension_id': extensionId,
      'dest_dir': destDir,
    });
    return result as String;
  }

  static Future<void> clearStoreCache() async {
    _log.d('clearStoreCache');
    await _channel.invokeMethod('clearStoreCache');
  }

  static Future<Map<String, dynamic>> parseCueSheet(
    String cuePath, {
    String audioDir = '',
  }) async {
    _log.i('parseCueSheet: $cuePath (audioDir: $audioDir)');
    final result = await _channel.invokeMethod('parseCueSheet', {
      'cue_path': cuePath,
      'audio_dir': audioDir,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }
}
