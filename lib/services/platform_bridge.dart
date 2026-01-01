import 'dart:convert';
import 'package:flutter/services.dart';

/// Bridge to communicate with Go backend via platform channels
class PlatformBridge {
  static const _channel = MethodChannel('com.zarz.spotiflac/backend');

  /// Parse and validate Spotify URL
  static Future<Map<String, dynamic>> parseSpotifyUrl(String url) async {
    final result = await _channel.invokeMethod('parseSpotifyUrl', {'url': url});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  /// Get Spotify metadata from URL
  static Future<Map<String, dynamic>> getSpotifyMetadata(String url) async {
    final result = await _channel.invokeMethod('getSpotifyMetadata', {'url': url});
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  /// Search Spotify
  static Future<Map<String, dynamic>> searchSpotify(String query, {int limit = 10}) async {
    final result = await _channel.invokeMethod('searchSpotify', {
      'query': query,
      'limit': limit,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  /// Check track availability on streaming services
  static Future<Map<String, dynamic>> checkAvailability(String spotifyId, String isrc) async {
    final result = await _channel.invokeMethod('checkAvailability', {
      'spotify_id': spotifyId,
      'isrc': isrc,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  /// Download a track from specific service
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
    bool convertLyricsToRomaji = false,
    int trackNumber = 1,
    int discNumber = 1,
    int totalTracks = 1,
    String? releaseDate,
    String? itemId,
  }) async {
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
      'convert_lyrics_to_romaji': convertLyricsToRomaji,
      'track_number': trackNumber,
      'disc_number': discNumber,
      'total_tracks': totalTracks,
      'release_date': releaseDate ?? '',
      'item_id': itemId ?? '',
    });
    
    final result = await _channel.invokeMethod('downloadTrack', request);
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  /// Download with automatic fallback to other services
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
    bool convertLyricsToRomaji = false,
    int trackNumber = 1,
    int discNumber = 1,
    int totalTracks = 1,
    String? releaseDate,
    String preferredService = 'tidal',
    String? itemId,
  }) async {
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
      'convert_lyrics_to_romaji': convertLyricsToRomaji,
      'track_number': trackNumber,
      'disc_number': discNumber,
      'total_tracks': totalTracks,
      'release_date': releaseDate ?? '',
      'item_id': itemId ?? '',
    });
    
    final result = await _channel.invokeMethod('downloadWithFallback', request);
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  /// Get download progress (legacy single download)
  static Future<Map<String, dynamic>> getDownloadProgress() async {
    final result = await _channel.invokeMethod('getDownloadProgress');
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  /// Get progress for all active downloads (concurrent mode)
  static Future<Map<String, dynamic>> getAllDownloadProgress() async {
    final result = await _channel.invokeMethod('getAllDownloadProgress');
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  /// Initialize progress tracking for a download item
  static Future<void> initItemProgress(String itemId) async {
    await _channel.invokeMethod('initItemProgress', {'item_id': itemId});
  }

  /// Finish progress tracking for a download item
  static Future<void> finishItemProgress(String itemId) async {
    await _channel.invokeMethod('finishItemProgress', {'item_id': itemId});
  }

  /// Clear progress tracking for a download item
  static Future<void> clearItemProgress(String itemId) async {
    await _channel.invokeMethod('clearItemProgress', {'item_id': itemId});
  }

  /// Set download directory
  static Future<void> setDownloadDirectory(String path) async {
    await _channel.invokeMethod('setDownloadDirectory', {'path': path});
  }

  /// Check if file with ISRC already exists
  static Future<Map<String, dynamic>> checkDuplicate(String outputDir, String isrc) async {
    final result = await _channel.invokeMethod('checkDuplicate', {
      'output_dir': outputDir,
      'isrc': isrc,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  /// Build filename from template
  static Future<String> buildFilename(String template, Map<String, dynamic> metadata) async {
    final result = await _channel.invokeMethod('buildFilename', {
      'template': template,
      'metadata': jsonEncode(metadata),
    });
    return result as String;
  }

  /// Sanitize filename
  static Future<String> sanitizeFilename(String filename) async {
    final result = await _channel.invokeMethod('sanitizeFilename', {
      'filename': filename,
    });
    return result as String;
  }

  /// Fetch lyrics for a track
  static Future<Map<String, dynamic>> fetchLyrics(
    String spotifyId,
    String trackName,
    String artistName,
  ) async {
    final result = await _channel.invokeMethod('fetchLyrics', {
      'spotify_id': spotifyId,
      'track_name': trackName,
      'artist_name': artistName,
    });
    return jsonDecode(result as String) as Map<String, dynamic>;
  }

  /// Get lyrics in LRC format
  static Future<String> getLyricsLRC(
    String spotifyId,
    String trackName,
    String artistName,
  ) async {
    final result = await _channel.invokeMethod('getLyricsLRC', {
      'spotify_id': spotifyId,
      'track_name': trackName,
      'artist_name': artistName,
    });
    return result as String;
  }

  /// Embed lyrics into an existing FLAC file
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

  /// Cleanup idle HTTP connections to prevent TCP exhaustion
  /// Call this periodically during large batch downloads
  static Future<void> cleanupConnections() async {
    await _channel.invokeMethod('cleanupConnections');
  }
}
