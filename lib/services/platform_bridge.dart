import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('PlatformBridge');

class PlatformBridge {
  static const _channel = MethodChannel('com.zarz.spotiflac/backend');

  static Future<Map<String, dynamic>> parseSpotifyUrl(String url) async {
    _log.d('parseSpotifyUrl: $url');
    final result = await _channel.invokeMethod('parseSpotifyUrl', {'url': url});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getSpotifyMetadata(String url) async {
    _log.d('getSpotifyMetadata: $url');
    final result = await _channel.invokeMethod('getSpotifyMetadata', {'url': url});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> searchSpotify(String query, {int limit = 10}) async {
    _log.d('searchSpotify: "$query" (limit: $limit)');
    final result = await _channel.invokeMethod('searchSpotify', {
      'query': query,
      'limit': limit,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> searchSpotifyAll(String query, {int trackLimit = 15, int artistLimit = 3}) async {
    _log.d('searchSpotifyAll: "$query"');
    final result = await _channel.invokeMethod('searchSpotifyAll', {
      'query': query,
      'track_limit': trackLimit,
      'artist_limit': artistLimit,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> checkAvailability(String spotifyId, String isrc) async {
    _log.d('checkAvailability: $spotifyId (ISRC: $isrc)');
    final result = await _channel.invokeMethod('checkAvailability', {
      'spotify_id': spotifyId,
      'isrc': isrc,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> downloadTrack({
    required String isrc,
    required String service,
    required String spotifyId,
    required String trackName,
    required String artistName,
    required String albumName,
    String? albumArtist,
    String? coverUrl,
    required String outputDir,
    required String filenameFormat,
    String quality = 'LOSSLESS',
    bool embedLyrics = true,
    bool embedMaxQualityCover = true,
    int trackNumber = 1,
    int discNumber = 1,
    int totalTracks = 1,
    String? releaseDate,
    String? itemId,
    int durationMs = 0,
  }) async {
    _log.i('downloadTrack: "$trackName" by $artistName via $service');
    final request = jsonEncode({
      'isrc': isrc,
      'service': service,
      'spotify_id': spotifyId,
      'track_name': trackName,
      'artist_name': artistName,
      'album_name': albumName,
      'album_artist': albumArtist ?? artistName,
      'cover_url': coverUrl,
      'output_dir': outputDir,
      'filename_format': filenameFormat,
      'quality': quality,
      'embed_lyrics': embedLyrics,
      'embed_max_quality_cover': embedMaxQualityCover,
      'track_number': trackNumber,
      'disc_number': discNumber,
      'total_tracks': totalTracks,
      'release_date': releaseDate ?? '',
      'item_id': itemId ?? '',
      'duration_ms': durationMs,
    });
    
    final result = await _channel.invokeMethod('downloadTrack', request);
    final response = jsonDecode(result as String) as Map<String, dynamic>;
    if (response['success'] == true) {
      _log.i('Download success: ${response['file_path']}');
    } else {
      _log.w('Download failed: ${response['error']}');
    }
    return response;
  }

  static Future<Map<String, dynamic>> downloadWithFallback({
    required String isrc,
    required String spotifyId,
    required String trackName,
    required String artistName,
    required String albumName,
    String? albumArtist,
    String? coverUrl,
    required String outputDir,
    required String filenameFormat,
    String quality = 'LOSSLESS',
    bool embedLyrics = true,
    bool embedMaxQualityCover = true,
    int trackNumber = 1,
    int discNumber = 1,
    int totalTracks = 1,
    String? releaseDate,
    String preferredService = 'tidal',
    String? itemId,
    int durationMs = 0,
    String? genre,
    String? label,
    String? copyright,
    String lyricsMode = 'embed',
  }) async {
    _log.i('downloadWithFallback: "$trackName" by $artistName (preferred: $preferredService)');
    final request = jsonEncode({
      'isrc': isrc,
      'service': preferredService,
      'spotify_id': spotifyId,
      'track_name': trackName,
      'artist_name': artistName,
      'album_name': albumName,
      'album_artist': albumArtist ?? artistName,
      'cover_url': coverUrl,
      'output_dir': outputDir,
      'filename_format': filenameFormat,
      'quality': quality,
      'embed_lyrics': embedLyrics,
      'embed_max_quality_cover': embedMaxQualityCover,
      'track_number': trackNumber,
      'disc_number': discNumber,
      'total_tracks': totalTracks,
      'release_date': releaseDate ?? '',
      'item_id': itemId ?? '',
      'duration_ms': durationMs,
      'genre': genre ?? '',
      'label': label ?? '',
      'copyright': copyright ?? '',
      'lyrics_mode': lyricsMode,
    });
    
    final result = await _channel.invokeMethod('downloadWithFallback', request);
    final response = jsonDecode(result as String) as Map<String, dynamic>;
    if (response['success'] == true) {
      final service = response['service'] ?? 'unknown';
      final filePath = response['file_path'] ?? '';
      final bitDepth = response['actual_bit_depth'];
      final sampleRate = response['actual_sample_rate'];
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
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getAllDownloadProgress() async {
    final result = await _channel.invokeMethod('getAllDownloadProgress');
    return jsonDecode(result as String) as Map<String, dynamic>;
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

  static Future<Map<String, dynamic>> checkDuplicate(String outputDir, String isrc) async {
    final result = await _channel.invokeMethod('checkDuplicate', {
      'output_dir': outputDir,
      'isrc': isrc,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<String> buildFilename(String template, Map<String, dynamic> metadata) async {
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

  static Future<Map<String, dynamic>> readFileMetadata(String filePath) async {
    final result = await _channel.invokeMethod('readFileMetadata', {
      'file_path': filePath,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
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

  static Future<void> setSpotifyCredentials(String clientId, String clientSecret) async {
    await _channel.invokeMethod('setSpotifyCredentials', {
      'client_id': clientId,
      'client_secret': clientSecret,
    });
  }

  static Future<bool> hasSpotifyCredentials() async {
    final result = await _channel.invokeMethod('hasSpotifyCredentials');
    return result as bool;
  }

  static Future<void> preWarmTrackCache(List<Map<String, String>> tracks) async {
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

  static Future<Map<String, dynamic>> searchDeezerAll(String query, {int trackLimit = 15, int artistLimit = 2, String? filter}) async {
    final result = await _channel.invokeMethod('searchDeezerAll', {
      'query': query,
      'track_limit': trackLimit,
      'artist_limit': artistLimit,
      'filter': filter ?? '',
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getDeezerMetadata(String resourceType, String resourceId) async {
    final result = await _channel.invokeMethod('getDeezerMetadata', {
      'resource_type': resourceType,
      'resource_id': resourceId,
    });
    if (result == null) {
      throw Exception('getDeezerMetadata returned null for $resourceType:$resourceId');
    }
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> parseDeezerUrl(String url) async {
    final result = await _channel.invokeMethod('parseDeezerUrl', {'url': url});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> parseTidalUrl(String url) async {
    final result = await _channel.invokeMethod('parseTidalUrl', {'url': url});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> convertTidalToSpotifyDeezer(String tidalUrl) async {
    final result = await _channel.invokeMethod('convertTidalToSpotifyDeezer', {'url': tidalUrl});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> searchDeezerByISRC(String isrc) async {
    final result = await _channel.invokeMethod('searchDeezerByISRC', {'isrc': isrc});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, String>?> getDeezerExtendedMetadata(String trackId) async {
    try {
      final result = await _channel.invokeMethod('getDeezerExtendedMetadata', {
        'track_id': trackId,
      });
      if (result == null) return null;
      final data = jsonDecode(result as String) as Map<String, dynamic>;
      return {
        'genre': data['genre'] as String? ?? '',
        'label': data['label'] as String? ?? '',
      };
    } catch (e) {
      _log.w('Failed to get Deezer extended metadata for $trackId: $e');
      return null;
    }
  }

  static Future<Map<String, dynamic>> convertSpotifyToDeezer(String resourceType, String spotifyId) async {
    final result = await _channel.invokeMethod('convertSpotifyToDeezer', {
      'resource_type': resourceType,
      'spotify_id': spotifyId,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> getSpotifyMetadataWithFallback(String url) async {
    final result = await _channel.invokeMethod('getSpotifyMetadataWithFallback', {'url': url});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<List<Map<String, dynamic>>> getGoLogs() async {
    final result = await _channel.invokeMethod('getLogs');
    final logs = jsonDecode(result as String) as List<dynamic>;
    return logs.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<Map<String, dynamic>> getGoLogsSince(int index) async {
    final result = await _channel.invokeMethod('getLogsSince', {'index': index});
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


  static Future<void> initExtensionSystem(String extensionsDir, String dataDir) async {
    _log.d('initExtensionSystem: $extensionsDir, $dataDir');
    await _channel.invokeMethod('initExtensionSystem', {
      'extensions_dir': extensionsDir,
      'data_dir': dataDir,
    });
  }

  static Future<Map<String, dynamic>> loadExtensionsFromDir(String dirPath) async {
    _log.d('loadExtensionsFromDir: $dirPath');
    final result = await _channel.invokeMethod('loadExtensionsFromDir', {
      'dir_path': dirPath,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<Map<String, dynamic>> loadExtensionFromPath(String filePath) async {
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

  static Future<Map<String, dynamic>> checkExtensionUpgrade(String filePath) async {
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

  static Future<void> setExtensionEnabled(String extensionId, bool enabled) async {
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

  static Future<void> setMetadataProviderPriority(List<String> providerIds) async {
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

  static Future<Map<String, dynamic>> getExtensionSettings(String extensionId) async {
    final result = await _channel.invokeMethod('getExtensionSettings', {
      'extension_id': extensionId,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<void> setExtensionSettings(String extensionId, Map<String, dynamic> settings) async {
    _log.d('setExtensionSettings: $extensionId');
    await _channel.invokeMethod('setExtensionSettings', {
      'extension_id': extensionId,
      'settings': jsonEncode(settings),
    });
  }

  static Future<Map<String, dynamic>> invokeExtensionAction(String extensionId, String actionName) async {
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

  static Future<List<Map<String, dynamic>>> searchTracksWithExtensions(String query, {int limit = 20}) async {
    _log.d('searchTracksWithExtensions: "$query"');
    final result = await _channel.invokeMethod('searchTracksWithExtensions', {
      'query': query,
      'limit': limit,
    });
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

static Future<Map<String, dynamic>> downloadWithExtensions({
    required String isrc,
    required String spotifyId,
    required String trackName,
    required String artistName,
    required String albumName,
    String? albumArtist,
    String? coverUrl,
    required String outputDir,
    required String filenameFormat,
    String quality = 'LOSSLESS',
    bool embedLyrics = true,
    bool embedMaxQualityCover = true,
    int trackNumber = 1,
    int discNumber = 1,
    int totalTracks = 1,
    String? releaseDate,
    String? itemId,
    int durationMs = 0,
    String? source,
    String? genre,
    String? label,
    String lyricsMode = 'embed',
    String? preferredService,
  }) async {
    _log.i('downloadWithExtensions: "$trackName" by $artistName${source != null ? ' (source: $source)' : ''}${preferredService != null ? ' (service: $preferredService)' : ''}');
    final request = jsonEncode({
      'isrc': isrc,
      'spotify_id': spotifyId,
      'track_name': trackName,
      'artist_name': artistName,
      'album_name': albumName,
      'album_artist': albumArtist ?? artistName,
      'cover_url': coverUrl,
      'output_dir': outputDir,
      'filename_format': filenameFormat,
      'quality': quality,
      'embed_lyrics': embedLyrics,
      'embed_max_quality_cover': embedMaxQualityCover,
      'track_number': trackNumber,
      'disc_number': discNumber,
      'total_tracks': totalTracks,
      'release_date': releaseDate ?? '',
      'item_id': itemId ?? '',
      'duration_ms': durationMs,
      'source': source ?? '',
      'genre': genre ?? '',
      'label': label ?? '',
      'lyrics_mode': lyricsMode,
      'service': preferredService ?? '',
    });
    
    final result = await _channel.invokeMethod('downloadWithExtensions', request);
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<void> cleanupExtensions() async {
    _log.d('cleanupExtensions');
    await _channel.invokeMethod('cleanupExtensions');
  }

  static Future<Map<String, dynamic>?> getExtensionPendingAuth(String extensionId) async {
    final result = await _channel.invokeMethod('getExtensionPendingAuth', {
      'extension_id': extensionId,
    });
    if (result == null) return null;
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  static Future<void> setExtensionAuthCode(String extensionId, String authCode) async {
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

  static Future<Map<String, dynamic>?> getPendingFFmpegCommand(String commandId) async {
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

  static Future<List<Map<String, dynamic>>> getAllPendingFFmpegCommands() async {
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

  static Future<Map<String, dynamic>?> handleURLWithExtension(String url) async {
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
    final result = await _channel.invokeMethod('findURLHandler', {
      'url': url,
    });
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

  static Future<Map<String, dynamic>?> getExtensionHomeFeed(String extensionId) async {
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

  static Future<Map<String, dynamic>?> getExtensionBrowseCategories(String extensionId) async {
    try {
      final result = await _channel.invokeMethod('getExtensionBrowseCategories', {
        'extension_id': extensionId,
      });
      if (result == null || result == '') return null;
      return jsonDecode(result as String) as Map<String, dynamic>;
    } catch (e) {
      _log.e('getExtensionBrowseCategories failed: $e');
      return null;
    }
  }

  // ==================== LOCAL LIBRARY SCANNING ====================

  /// Set the directory for caching extracted cover art
  static Future<void> setLibraryCoverCacheDir(String cacheDir) async {
    _log.i('setLibraryCoverCacheDir: $cacheDir');
    await _channel.invokeMethod('setLibraryCoverCacheDir', {
      'cache_dir': cacheDir,
    });
  }

  /// Scan a folder for audio files and read their metadata
  /// Returns a list of track metadata
  static Future<List<Map<String, dynamic>>> scanLibraryFolder(String folderPath) async {
    _log.i('scanLibraryFolder: $folderPath');
    final result = await _channel.invokeMethod('scanLibraryFolder', {
      'folder_path': folderPath,
    });
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  /// Get current library scan progress
  static Future<Map<String, dynamic>> getLibraryScanProgress() async {
    final result = await _channel.invokeMethod('getLibraryScanProgress');
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  /// Cancel ongoing library scan
  static Future<void> cancelLibraryScan() async {
    await _channel.invokeMethod('cancelLibraryScan');
  }

  /// Read metadata from a single audio file
  static Future<Map<String, dynamic>?> readAudioMetadata(String filePath) async {
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

  static Future<List<Map<String, dynamic>>> getPostProcessingProviders() async {
    final result = await _channel.invokeMethod('getPostProcessingProviders');
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }


  static Future<void> initExtensionStore(String cacheDir) async {
    _log.d('initExtensionStore: $cacheDir');
    await _channel.invokeMethod('initExtensionStore', {'cache_dir': cacheDir});
  }

  static Future<List<Map<String, dynamic>>> getStoreExtensions({bool forceRefresh = false}) async {
    _log.d('getStoreExtensions (forceRefresh: $forceRefresh)');
    final result = await _channel.invokeMethod('getStoreExtensions', {
      'force_refresh': forceRefresh,
    });
    final list = jsonDecode(result as String) as List<dynamic>;
    return list.map((e) => e as Map<String, dynamic>).toList();
  }

  static Future<List<Map<String, dynamic>>> searchStoreExtensions(String query, {String? category}) async {
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

  static Future<String> downloadStoreExtension(String extensionId, String destDir) async {
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
}
