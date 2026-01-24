import 'dart:io';
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:spotiflac_android/models/webdav_config.dart';
import 'package:spotiflac_android/utils/logger.dart';
import 'package:path/path.dart' as p;

final _log = AppLogger('WebDavService');

class WebDavService {
  webdav.Client? _client;
  WebDavConfig? _config;

  static final WebDavService _instance = WebDavService._internal();
  factory WebDavService() => _instance;
  WebDavService._internal();

  void configure(WebDavConfig config) {
    _config = config;
    if (config.isConfigured) {
      _client = webdav.newClient(
        config.serverUrl,
        user: config.username,
        password: config.password,
        debug: false,
      );
      _log.i('WebDAV client configured for: ${config.serverUrl}');
    } else {
      _client = null;
      _log.d('WebDAV client cleared - configuration incomplete');
    }
  }

  bool get isConfigured => _config?.isConfigured ?? false;
  bool get isEnabled => _config?.enabled ?? false;
  WebDavConfig? get config => _config;

  /// Test the WebDAV connection
  Future<({bool success, String? error})> testConnection() async {
    if (_client == null || _config == null) {
      return (success: false, error: 'WebDAV not configured');
    }

    try {
      // Try to ping the server
      await _client!.ping();
      _log.i('WebDAV connection test successful');
      return (success: true, error: null);
    } catch (e) {
      _log.e('WebDAV connection test failed: $e');
      return (success: false, error: e.toString());
    }
  }

  /// Ensure the remote directory exists
  Future<void> _ensureRemoteDir(String remotePath) async {
    if (_client == null) return;

    final parts = remotePath.split('/').where((p) => p.isNotEmpty).toList();
    var currentPath = '';

    for (final part in parts) {
      currentPath = '$currentPath/$part';
      try {
        await _client!.mkdir(currentPath);
      } catch (e) {
        // Directory might already exist, ignore error
        _log.d('mkdir $currentPath: $e');
      }
    }
  }

  /// Upload a file to WebDAV server
  /// Returns the remote path on success, or throws an exception on failure
  Future<String> uploadFile(
    String localPath,
    String remotePath, {
    void Function(double progress)? onProgress,
    CancelToken? cancelToken,
  }) async {
    if (_client == null || _config == null) {
      throw Exception('WebDAV not configured');
    }

    final file = File(localPath);
    if (!await file.exists()) {
      throw Exception('Local file does not exist: $localPath');
    }

    final fileSize = await file.length();
    final remoteDir = p.dirname(remotePath);

    _log.d(
      'Uploading $localPath to $remotePath (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)',
    );

    // Ensure remote directory exists
    await _ensureRemoteDir(remoteDir);

    // Upload the file
    var lastReportedProgress = 0.0;

    try {
      await _client!.writeFromFile(
        localPath,
        remotePath,
        onProgress: (current, total) {
          if (cancelToken?.isCancelled ?? false) {
            throw Exception('Upload cancelled');
          }
          final progress = total > 0 ? current / total : 0.0;
          if (progress - lastReportedProgress >= 0.01 || progress == 1.0) {
            lastReportedProgress = progress;
            onProgress?.call(progress);
          }
        },
      );

      _log.i('Successfully uploaded to: $remotePath');
      return remotePath;
    } catch (e) {
      _log.e('Upload failed: $e');
      rethrow;
    }
  }

  /// Delete a local file after successful upload
  Future<bool> deleteLocalFile(String localPath) async {
    try {
      final file = File(localPath);
      if (await file.exists()) {
        await file.delete();
        _log.d('Deleted local file: $localPath');
        return true;
      }
      return false;
    } catch (e) {
      _log.e('Failed to delete local file: $e');
      return false;
    }
  }

  /// Build the remote path for a downloaded file
  String buildRemotePath(
    String localFilePath, {
    String? albumName,
    String? artistName,
  }) {
    final basePath = _config?.remotePath ?? '/SpotiFLAC';
    final fileName = p.basename(localFilePath);

    if (albumName != null && artistName != null) {
      final sanitizedArtist = _sanitizePathComponent(artistName);
      final sanitizedAlbum = _sanitizePathComponent(albumName);
      return '$basePath/$sanitizedArtist/$sanitizedAlbum/$fileName';
    } else if (artistName != null) {
      final sanitizedArtist = _sanitizePathComponent(artistName);
      return '$basePath/$sanitizedArtist/$fileName';
    }

    return '$basePath/$fileName';
  }

  String _sanitizePathComponent(String name) {
    return name
        .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
        .replaceAll(RegExp(r'\.+$'), '')
        .trim();
  }
}

/// A simple cancel token for upload operations
class CancelToken {
  bool _isCancelled = false;

  bool get isCancelled => _isCancelled;

  void cancel() {
    _isCancelled = true;
  }
}
