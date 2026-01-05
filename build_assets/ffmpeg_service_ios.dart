import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('FFmpeg');

/// FFmpeg service for iOS using ffmpeg_kit_flutter plugin
class FFmpegServiceIOS {
  /// Execute FFmpeg command and return result
  static Future<FFmpegResultIOS> _execute(String command) async {
    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final output = await session.getOutput() ?? '';
      return FFmpegResultIOS(
        success: ReturnCode.isSuccess(returnCode),
        returnCode: returnCode?.getValue() ?? -1,
        output: output,
      );
    } catch (e) {
      _log.e('FFmpeg execute error: $e');
      return FFmpegResultIOS(success: false, returnCode: -1, output: e.toString());
    }
  }

  /// Convert M4A (DASH segments) to FLAC
  static Future<String?> convertM4aToFlac(String inputPath) async {
    final outputPath = inputPath.replaceAll('.m4a', '.flac');
    final command = '-i "$inputPath" -c:a flac -compression_level 8 "$outputPath" -y';
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
  static Future<String?> convertFlacToMp3(String inputPath, {String bitrate = '320k'}) async {
    final dir = File(inputPath).parent.path;
    final baseName = inputPath.split(Platform.pathSeparator).last.replaceAll('.flac', '');
    final outputDir = '$dir${Platform.pathSeparator}MP3';
    await Directory(outputDir).create(recursive: true);
    final outputPath = '$outputDir${Platform.pathSeparator}$baseName.mp3';

    final command = '-i "$inputPath" -codec:a libmp3lame -b:a $bitrate -map 0:a -map_metadata 0 -id3v2_version 3 "$outputPath" -y';
    final result = await _execute(command);

    if (result.success) return outputPath;
    _log.e('FLAC to MP3 conversion failed: ${result.output}');
    return null;
  }

  /// Convert FLAC to M4A
  static Future<String?> convertFlacToM4a(String inputPath, {String codec = 'aac', String bitrate = '256k'}) async {
    final dir = File(inputPath).parent.path;
    final baseName = inputPath.split(Platform.pathSeparator).last.replaceAll('.flac', '');
    final outputDir = '$dir${Platform.pathSeparator}M4A';
    await Directory(outputDir).create(recursive: true);
    final outputPath = '$outputDir${Platform.pathSeparator}$baseName.m4a';

    String command;
    if (codec == 'alac') {
      command = '-i "$inputPath" -codec:a alac -map 0:a -map_metadata 0 "$outputPath" -y';
    } else {
      command = '-i "$inputPath" -codec:a aac -b:a $bitrate -map 0:a -map_metadata 0 "$outputPath" -y';
    }

    final result = await _execute(command);
    if (result.success) return outputPath;
    _log.e('FLAC to M4A conversion failed: ${result.output}');
    return null;
  }

  /// Embed cover art to FLAC file
  static Future<String?> embedCover(String flacPath, String coverPath) async {
    final tempOutput = '$flacPath.tmp';
    final command = '-i "$flacPath" -i "$coverPath" -map 0:a -map 1:0 -c copy -metadata:s:v title="Album cover" -metadata:s:v comment="Cover (front)" -disposition:v attached_pic "$tempOutput" -y';

    final result = await _execute(command);

    if (result.success) {
      try {
        await File(flacPath).delete();
        await File(tempOutput).rename(flacPath);
        return flacPath;
      } catch (e) {
        _log.e('Failed to replace file after cover embed: $e');
        return null;
      }
    }

    try {
      final tempFile = File(tempOutput);
      if (await tempFile.exists()) await tempFile.delete();
    } catch (_) {}

    _log.e('Cover embed failed: ${result.output}');
    return null;
  }

  /// Check if FFmpeg is available
  static Future<bool> isAvailable() async {
    try {
      final session = await FFmpegKit.execute('-version');
      final returnCode = await session.getReturnCode();
      return ReturnCode.isSuccess(returnCode);
    } catch (e) {
      return false;
    }
  }

  /// Get FFmpeg version info
  static Future<String?> getVersion() async {
    try {
      final session = await FFmpegKit.execute('-version');
      return await session.getOutput();
    } catch (e) {
      return null;
    }
  }
}

class FFmpegResultIOS {
  final bool success;
  final int returnCode;
  final String output;

  FFmpegResultIOS({required this.success, required this.returnCode, required this.output});
}
