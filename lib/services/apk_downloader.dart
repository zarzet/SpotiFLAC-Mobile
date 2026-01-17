import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('ApkDownloader');

typedef ProgressCallback = void Function(int received, int total);

class ApkDownloader {
  static Future<String?> downloadApk({
    required String url,
    required String version,
    ProgressCallback? onProgress,
  }) async {
    final uri = Uri.tryParse(url);
    if (uri == null || uri.scheme != 'https') {
      _log.e('Refusing to download from invalid or non-HTTPS URL');
      return null;
    }

    final client = http.Client();
    IOSink? sink;
    
    try {
      final request = http.Request('GET', uri);
      final response = await client.send(request);

      if (response.statusCode != 200) {
        _log.e('Failed to download: ${response.statusCode}');
        return null;
      }

      final contentLength = response.contentLength ?? 0;
      
      final dir = await getExternalStorageDirectory();
      if (dir == null) {
        _log.e('Could not get storage directory');
        return null;
      }

      final filePath = '${dir.path}/SpotiFLAC-$version.apk';
      final file = File(filePath);
      
      if (await file.exists()) {
        await file.delete();
      }

      sink = file.openWrite();
      int received = 0;

      await for (final chunk in response.stream) {
        sink.add(chunk);
        received += chunk.length;
        onProgress?.call(received, contentLength);
      }

      await sink.flush();
      _log.i('Downloaded to: $filePath');
      return filePath;
    } catch (e) {
      _log.e('Error: $e');
      return null;
    } finally {
      await sink?.close();
      client.close();
    }
  }

  static Future<void> installApk(String filePath) async {
    try {
      final result = await OpenFilex.open(filePath);
      _log.i('Open result: ${result.type} - ${result.message}');
    } catch (e) {
      _log.e('Install error: $e');
    }
  }
}
