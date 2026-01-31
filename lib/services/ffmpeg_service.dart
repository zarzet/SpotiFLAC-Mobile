import 'dart:io';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_audio/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_audio/return_code.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('FFmpeg');

/// FFmpeg service for audio conversion and remuxing
/// Uses ffmpeg_kit_flutter_new_audio plugin
class FFmpegService {
  static Future<FFmpegResult> _execute(String command) async {
    try {
      final session = await FFmpegKit.execute(command);
      final returnCode = await session.getReturnCode();
      final output = await session.getOutput() ?? '';
      
      return FFmpegResult(
        success: ReturnCode.isSuccess(returnCode),
        returnCode: returnCode?.getValue() ?? -1,
        output: output,
      );
    } catch (e) {
      _log.e('FFmpeg execute error: $e');
      return FFmpegResult(success: false, returnCode: -1, output: e.toString());
    }
  }

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

  static Future<String?> convertFlacToMp3(
    String inputPath, {
    String bitrate = '320k',
    bool deleteOriginal = true,
  }) async {
    final outputPath = inputPath.replaceAll('.flac', '.mp3');

    final command =
        '-i "$inputPath" -codec:a libmp3lame -b:a $bitrate -map 0:a -map_metadata 0 -id3v2_version 3 "$outputPath" -y';

    final result = await _execute(command);

    if (result.success) {
      if (deleteOriginal) {
        try {
          await File(inputPath).delete();
        } catch (_) {}
      }
      return outputPath;
    }

    _log.e('FLAC to MP3 conversion failed: ${result.output}');
    return null;
  }

  static Future<String?> convertFlacToOpus(
    String inputPath, {
    String bitrate = '128k',
    bool deleteOriginal = true,
  }) async {
    final outputPath = inputPath.replaceAll('.flac', '.opus');

    // Opus in OGG container with VBR
    final command =
        '-i "$inputPath" -codec:a libopus -b:a $bitrate -vbr on -compression_level 10 -map 0:a -map_metadata 0 "$outputPath" -y';

    final result = await _execute(command);

    if (result.success) {
      if (deleteOriginal) {
        try {
          await File(inputPath).delete();
        } catch (_) {}
      }
      return outputPath;
    }

    _log.e('FLAC to Opus conversion failed: ${result.output}');
    return null;
  }

  /// Convert FLAC to lossy format based on format parameter
  /// format: 'mp3' or 'opus'
  static Future<String?> convertFlacToLossy(
    String inputPath, {
    required String format,
    bool deleteOriginal = true,
  }) async {
    switch (format.toLowerCase()) {
      case 'opus':
        return convertFlacToOpus(inputPath, deleteOriginal: deleteOriginal);
      case 'mp3':
      default:
        return convertFlacToMp3(inputPath, deleteOriginal: deleteOriginal);
    }
  }

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

  static Future<bool> isAvailable() async {
    try {
      final version = await FFmpegKitConfig.getFFmpegVersion();
      return version?.isNotEmpty ?? false;
    } catch (e) {
      return false;
    }
  }

  static Future<String?> getVersion() async {
    try {
      return await FFmpegKitConfig.getFFmpegVersion();
    } catch (e) {
      return null;
    }
  }

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
    } catch (e) {
      _log.w('Failed to cleanup temp file: $e');
    }

    _log.e('Metadata/Cover embed failed: ${result.output}');
    return null;
  }

  static Future<String?> embedMetadataToMp3({
    required String mp3Path,
    String? coverPath,
    Map<String, String>? metadata,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final uniqueId = DateTime.now().millisecondsSinceEpoch;
    final tempOutput = '${tempDir.path}/temp_embed_$uniqueId.mp3';
    
    final StringBuffer cmdBuffer = StringBuffer();
    cmdBuffer.write('-i "$mp3Path" ');
    
    if (coverPath != null) {
      cmdBuffer.write('-i "$coverPath" ');
    }
    
    cmdBuffer.write('-map 0:a ');
    
    if (coverPath != null) {
      cmdBuffer.write('-map 1:0 ');
      cmdBuffer.write('-c:v:0 copy ');
      cmdBuffer.write('-id3v2_version 3 ');
      cmdBuffer.write('-metadata:s:v title="Album cover" ');
      cmdBuffer.write('-metadata:s:v comment="Cover (front)" ');
    }
    
    cmdBuffer.write('-c:a copy ');
    
    if (metadata != null) {
      final id3Metadata = _convertToId3Tags(metadata);
      id3Metadata.forEach((key, value) {
        final sanitizedValue = value.replaceAll('"', '\\"');
        cmdBuffer.write('-metadata $key="$sanitizedValue" ');
      });
    }
    
    cmdBuffer.write('-id3v2_version 3 "$tempOutput" -y');
    
    final command = cmdBuffer.toString();
    _log.d('Executing FFmpeg MP3 embed command: $command');

    final result = await _execute(command);

    if (result.success) {
      try {
        final tempFile = File(tempOutput);
        final originalFile = File(mp3Path);
        
        if (await tempFile.exists()) {
             if (await originalFile.exists()) {
               await originalFile.delete();
             }
             await tempFile.copy(mp3Path);
             await tempFile.delete();
             
             _log.d('MP3 metadata embedded successfully');
             return mp3Path;
        } else {
             _log.e('Temp MP3 output file not found: $tempOutput');
             return null;
        }

      } catch (e) {
        _log.e('Failed to replace MP3 file after metadata embed: $e');
        return null;
      }
    }

    try {
      final tempFile = File(tempOutput);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      _log.w('Failed to cleanup temp MP3 file: $e');
    }

    _log.e('MP3 Metadata/Cover embed failed: ${result.output}');
    return null;
  }

  static Map<String, String> _convertToId3Tags(Map<String, String> vorbisMetadata) {
    final id3Map = <String, String>{};
    
    for (final entry in vorbisMetadata.entries) {
      final key = entry.key.toUpperCase();
      final value = entry.value;
      
      // Map Vorbis comments to ID3v2 frame names
      switch (key) {
        case 'TITLE':
          id3Map['title'] = value;
          break;
        case 'ARTIST':
          id3Map['artist'] = value;
          break;
        case 'ALBUM':
          id3Map['album'] = value;
          break;
        case 'ALBUMARTIST':
          id3Map['album_artist'] = value;
          break;
        case 'TRACKNUMBER':
        case 'TRACK':
          id3Map['track'] = value;
          break;
        case 'DISCNUMBER':
        case 'DISC':
          id3Map['disc'] = value;
          break;
        case 'DATE':
        case 'YEAR':
          id3Map['date'] = value;
          break;
        case 'ISRC':
          id3Map['TSRC'] = value;
          break;
        case 'LYRICS':
        case 'UNSYNCEDLYRICS':
          id3Map['lyrics'] = value;
          break;
        default:
          // Pass through other tags as-is
          id3Map[key.toLowerCase()] = value;
      }
    }
    
    return id3Map;
  }
}

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
