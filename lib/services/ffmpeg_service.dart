import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('FFmpeg');

/// FFmpeg service for audio conversion and remuxing
/// Uses native MethodChannel to call FFmpegKit from local AAR
class FFmpegService {
  static const _channel = MethodChannel('com.zarz.spotiflac/ffmpeg');

  /// Execute FFmpeg command and return result
  static Future<FFmpegResult> _execute(String command) async {
    try {
      final result = await _channel.invokeMethod('execute', {'command': command});
      final map = Map<String, dynamic>.from(result);
      return FFmpegResult(
        success: map['success'] as bool,
        returnCode: map['returnCode'] as int,
        output: map['output'] as String,
      );
    } catch (e) {
      _log.e('FFmpeg execute error: $e');
      return FFmpegResult(success: false, returnCode: -1, output: e.toString());
    }
  }

  /// Convert M4A (DASH segments) to FLAC
  /// Returns the output file path on success, null on failure
  static Future<String?> convertM4aToFlac(String inputPath) async {
    final outputPath = inputPath.replaceAll('.m4a', '.flac');

    final command =
        '-i "$inputPath" -c:a flac -compression_level 8 "$outputPath" -y';

    final result = await _execute(command);

    if (result.success) {
      try {
        await File(inputPath).delete();
      } catch (_) {}
      return outputPath;
    }

    _log.e('M4A to FLAC conversion failed: ${result.output}');
    return null;
  }

  /// Convert FLAC to MP3
  static Future<String?> convertFlacToMp3(
    String inputPath, {
    String bitrate = '320k',
  }) async {
    final dir = File(inputPath).parent.path;
    final baseName =
        inputPath.split(Platform.pathSeparator).last.replaceAll('.flac', '');
    final outputDir = '$dir${Platform.pathSeparator}MP3';

    await Directory(outputDir).create(recursive: true);

    final outputPath = '$outputDir${Platform.pathSeparator}$baseName.mp3';

    final command =
        '-i "$inputPath" -codec:a libmp3lame -b:a $bitrate -map 0:a -map_metadata 0 -id3v2_version 3 "$outputPath" -y';

    final result = await _execute(command);

    if (result.success) {
      return outputPath;
    }

    _log.e('FLAC to MP3 conversion failed: ${result.output}');
    return null;
  }

  /// Convert FLAC to M4A (AAC or ALAC)
  static Future<String?> convertFlacToM4a(
    String inputPath, {
    String codec = 'aac',
    String bitrate = '256k',
  }) async {
    final dir = File(inputPath).parent.path;
    final baseName =
        inputPath.split(Platform.pathSeparator).last.replaceAll('.flac', '');
    final outputDir = '$dir${Platform.pathSeparator}M4A';

    await Directory(outputDir).create(recursive: true);

    final outputPath = '$outputDir${Platform.pathSeparator}$baseName.m4a';

    String command;
    if (codec == 'alac') {
      command =
          '-i "$inputPath" -codec:a alac -map 0:a -map_metadata 0 "$outputPath" -y';
    } else {
      command =
          '-i "$inputPath" -codec:a aac -b:a $bitrate -map 0:a -map_metadata 0 "$outputPath" -y';
    }

    final result = await _execute(command);

    if (result.success) {
      return outputPath;
    }

    _log.e('FLAC to M4A conversion failed: ${result.output}');
    return null;
  }

  /// Check if FFmpeg is available
  static Future<bool> isAvailable() async {
    try {
      final version = await _channel.invokeMethod('getVersion');
      return version != null && version.toString().isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get FFmpeg version info
  static Future<String?> getVersion() async {
    try {
      final version = await _channel.invokeMethod('getVersion');
      return version as String?;
    } catch (e) {
      return null;
    }
  }

  /// Embed metadata and cover art to FLAC file
  /// Returns the file path on success, null on failure
  static Future<String?> embedMetadata({
    required String flacPath,
    String? coverPath,
    Map<String, String>? metadata,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    final tempOutput = '${tempDir.path}/temp_embed_$uniqueId.flac';
    
    final StringBuffer cmdBuffer = StringBuffer();
    cmdBuffer.write('-i "$flacPath" ');
    
    if (coverPath != null) {
      cmdBuffer.write('-i "$coverPath" ');
    }
    
    cmdBuffer.write('-map 0:a ');
    
    if (coverPath != null) {
      cmdBuffer.write('-map 1:0 ');
      cmdBuffer.write('-c:v copy ');
      cmdBuffer.write('-disposition:v attached_pic ');
      cmdBuffer.write('-metadata:s:v title="Album cover" ');
      cmdBuffer.write('-metadata:s:v comment="Cover (front)" ');
    }
    
    cmdBuffer.write('-c:a copy ');
    
    if (metadata != null) {
      metadata.forEach((key, value) {
        final sanitizedValue = value.replaceAll('"', '\\"');
        cmdBuffer.write('-metadata $key="$sanitizedValue" ');
      });
    }
    
    cmdBuffer.write('"$tempOutput" -y');
    
    final command = cmdBuffer.toString();
    _log.d('Executing FFmpeg command: $command');

    final result = await _execute(command);

    if (result.success) {
      try {
        final tempFile = File(tempOutput);
        final originalFile = File(flacPath);
        
        if (await tempFile.exists()) {
             if (await originalFile.exists()) {
               await originalFile.delete();
             }
             await tempFile.copy(flacPath);
             await tempFile.delete();
             
             return flacPath;
        } else {
             _log.e('Temp output file not found: $tempOutput');
             return null;
        }

      } catch (e) {
        _log.e('Failed to replace file after metadata embed: $e');
        return null;
      }
    }

    try {
      final tempFile = File(tempOutput);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (_) {}

    _log.e('Metadata/Cover embed failed: ${result.output}');
    return null;
  }
}

/// Result of FFmpeg command execution
class FFmpegResult {
  final bool success;
  final int returnCode;
  final String output;

  FFmpegResult({
    required this.success,
    required this.returnCode,
    required this.output,
  });
}
