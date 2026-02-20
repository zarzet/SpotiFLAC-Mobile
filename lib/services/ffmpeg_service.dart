import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_full/session_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('FFmpeg');

class FFmpegService {
  static const int _commandLogPreviewLength = 300;
  static int _tempEmbedCounter = 0;
  static FFmpegSession? _activeLiveDecryptSession;
  static String? _activeLiveDecryptUrl;

  static String _buildOutputPath(String inputPath, String extension) {
    final normalizedExt = extension.startsWith('.') ? extension : '.$extension';
    final inputFile = File(inputPath);
    final dir = inputFile.parent.path;
    final filename = inputFile.uri.pathSegments.last;
    final dotIndex = filename.lastIndexOf('.');
    final baseName = dotIndex > 0 ? filename.substring(0, dotIndex) : filename;
    var outputPath = '$dir${Platform.pathSeparator}$baseName$normalizedExt';

    if (outputPath == inputPath) {
      outputPath =
          '$dir${Platform.pathSeparator}${baseName}_converted$normalizedExt';
    }
    return outputPath;
  }

  static String _previewCommandForLog(String command) {
    final redacted = command
        .replaceAll(
          RegExp(r'-metadata\s+lyrics="[^"]*"', caseSensitive: false),
          '-metadata lyrics="<redacted>"',
        )
        .replaceAll(
          RegExp(r'-metadata\s+unsyncedlyrics="[^"]*"', caseSensitive: false),
          '-metadata unsyncedlyrics="<redacted>"',
        )
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (redacted.length <= _commandLogPreviewLength) {
      return redacted;
    }
    return '${redacted.substring(0, _commandLogPreviewLength)}...';
  }

  static String _nextTempEmbedPath(String tempDirPath, String extension) {
    final normalizedExt = extension.startsWith('.') ? extension : '.$extension';
    _tempEmbedCounter = (_tempEmbedCounter + 1) & 0x7fffffff;
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    final processId = pid;
    return '$tempDirPath${Platform.pathSeparator}temp_embed_${timestamp}_${processId}_$_tempEmbedCounter$normalizedExt';
  }

  static List<String> _buildDecryptionKeyCandidates(String rawKey) {
    final candidates = <String>[];

    void addCandidate(String key) {
      final normalized = key.trim();
      if (normalized.isEmpty) return;
      if (!candidates.contains(normalized)) {
        candidates.add(normalized);
      }
    }

    final trimmed = rawKey.trim();
    if (trimmed.isEmpty) return candidates;

    addCandidate(trimmed);

    final noPrefix = trimmed.startsWith(RegExp(r'0x', caseSensitive: false))
        ? trimmed.substring(2)
        : trimmed;
    addCandidate(noPrefix);

    final compactHex = noPrefix.replaceAll(RegExp(r'[^0-9a-fA-F]'), '');
    if (compactHex.isNotEmpty && compactHex.length.isEven) {
      addCandidate(compactHex);
    }

    try {
      final b64 = noPrefix.replaceAll(RegExp(r'\s+'), '');
      final decoded = base64Decode(b64);
      if (decoded.isNotEmpty) {
        final hex = decoded
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();
        if (hex.isNotEmpty) {
          addCandidate(hex);
        }
      }
    } catch (_) {}

    return candidates;
  }

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
    final outputPath = _buildOutputPath(inputPath, '.flac');

    final command =
        '-v error -xerror -i "$inputPath" -c:a flac -compression_level 8 "$outputPath" -y';

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

  static Future<String?> convertM4aToLossy(
    String inputPath, {
    required String format,
    String? bitrate,
    bool deleteOriginal = true,
  }) async {
    String bitrateValue = format == 'opus' ? '128k' : '320k';
    if (bitrate != null && bitrate.contains('_')) {
      final parts = bitrate.split('_');
      if (parts.length == 2) {
        bitrateValue = '${parts[1]}k';
      }
    }

    final extension = format == 'opus' ? '.opus' : '.mp3';
    final outputPath = _buildOutputPath(inputPath, extension);

    String command;
    if (format == 'opus') {
      command =
          '-i "$inputPath" -codec:a libopus -b:a $bitrateValue -vbr on -compression_level 10 -map 0:a "$outputPath" -y';
    } else {
      command =
          '-i "$inputPath" -codec:a libmp3lame -b:a $bitrateValue -map 0:a -id3v2_version 3 "$outputPath" -y';
    }

    final result = await _execute(command);

    if (result.success) {
      if (deleteOriginal) {
        try {
          await File(inputPath).delete();
        } catch (_) {}
      }
      return outputPath;
    }

    _log.e('M4A to $format conversion failed: ${result.output}');
    return null;
  }

  static Future<String?> decryptAudioFile({
    required String inputPath,
    required String decryptionKey,
    bool deleteOriginal = true,
  }) async {
    final trimmedKey = decryptionKey.trim();
    if (trimmedKey.isEmpty) return inputPath;

    // Amazon encrypted streams are commonly MP4 container with FLAC audio.
    // Prefer FLAC output to avoid MP4 muxing errors during decrypt copy.
    final preferredExt = inputPath.toLowerCase().endsWith('.m4a')
        ? '.flac'
        : inputPath.toLowerCase().endsWith('.flac')
        ? '.flac'
        : inputPath.toLowerCase().endsWith('.mp3')
        ? '.mp3'
        : inputPath.toLowerCase().endsWith('.opus')
        ? '.opus'
        : '.flac';
    var tempOutput = _buildOutputPath(inputPath, preferredExt);

    String buildDecryptCommand(
      String outputPath, {
      required bool mapAudioOnly,
      required String key,
    }) {
      final audioMap = mapAudioOnly ? '-map 0:a ' : '';
      return '-v error -decryption_key "$key" -i "$inputPath" $audioMap-c copy "$outputPath" -y';
    }

    final keyCandidates = _buildDecryptionKeyCandidates(trimmedKey);
    if (keyCandidates.isEmpty) {
      _log.e('No usable decryption key candidates');
      return null;
    }

    FFmpegResult? lastResult;
    var decryptSucceeded = false;

    for (final keyCandidate in keyCandidates) {
      _log.d(
        'Executing FFmpeg decrypt command (key length: ${keyCandidate.length})',
      );
      var result = await _execute(
        buildDecryptCommand(
          tempOutput,
          mapAudioOnly: preferredExt == '.flac',
          key: keyCandidate,
        ),
      );

      // Fallback for uncommon streams that cannot be remuxed into FLAC.
      if (!result.success && preferredExt == '.flac') {
        final fallbackOutput = _buildOutputPath(inputPath, '.m4a');
        final fallbackResult = await _execute(
          buildDecryptCommand(
            fallbackOutput,
            mapAudioOnly: false,
            key: keyCandidate,
          ),
        );
        if (fallbackResult.success) {
          tempOutput = fallbackOutput;
          result = fallbackResult;
        }
      }

      if (result.success) {
        decryptSucceeded = true;
        lastResult = result;
        break;
      }

      try {
        final tempFile = File(tempOutput);
        if (await tempFile.exists()) {
          await tempFile.delete();
        }
      } catch (_) {}
      lastResult = result;
    }

    if (!decryptSucceeded) {
      _log.e('FFmpeg decrypt failed: ${lastResult?.output ?? 'unknown error'}');
      return null;
    }

    try {
      final tempFile = File(tempOutput);
      final inputFile = File(inputPath);
      if (!await tempFile.exists()) {
        _log.e('Decrypted output file not found: $tempOutput');
        return null;
      }

      if (deleteOriginal && await inputFile.exists()) {
        await inputFile.delete();
      }
      return tempOutput;
    } catch (e) {
      _log.e('Failed to finalize decrypted file: $e');
      return null;
    }
  }

  static Future<String?> convertFlacToMp3(
    String inputPath, {
    String bitrate = '320k',
    bool deleteOriginal = true,
  }) async {
    final outputPath = _buildOutputPath(inputPath, '.mp3');

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

  static bool isActiveLiveDecryptedUrl(String url) {
    final active = _activeLiveDecryptUrl;
    if (active == null || active.isEmpty) return false;
    return active == url.trim();
  }

  static Future<void> stopLiveDecryptedStream() async {
    final session = _activeLiveDecryptSession;
    _activeLiveDecryptSession = null;
    _activeLiveDecryptUrl = null;
    if (session == null) return;

    try {
      await session.cancel();
    } catch (e) {
      final sessionId = session.getSessionId();
      if (sessionId != null) {
        try {
          await FFmpegKit.cancel(sessionId);
        } catch (_) {}
      }
      _log.w('Failed to stop live decrypt session cleanly: $e');
    }
  }

  static Future<LiveDecryptedStreamResult?> startAmazonLiveDecryptedStream({
    required String encryptedStreamUrl,
    required String decryptionKey,
    String preferredFormat = 'flac',
  }) async {
    final inputUrl = encryptedStreamUrl.trim();
    if (inputUrl.isEmpty) return null;

    final keyCandidates = _buildDecryptionKeyCandidates(decryptionKey);
    if (keyCandidates.isEmpty) {
      _log.e('No usable decryption key candidates for live stream');
      return null;
    }

    await stopLiveDecryptedStream();

    final attempts = _buildLiveDecryptFormatAttempts(preferredFormat);
    for (final format in attempts) {
      for (final keyCandidate in keyCandidates) {
        final stream = await _tryStartLiveDecryptAttempt(
          inputUrl: inputUrl,
          decryptionKey: keyCandidate,
          format: format,
        );
        if (stream != null) {
          _activeLiveDecryptSession = stream.session;
          _activeLiveDecryptUrl = stream.localUrl;
          return stream;
        }
      }
    }

    return null;
  }

  static List<_LiveDecryptFormat> _buildLiveDecryptFormatAttempts(
    String preferredFormat,
  ) {
    final normalized = preferredFormat.trim().toLowerCase();
    if (normalized == 'm4a' || normalized == 'mp4' || normalized == 'aac') {
      return const [_LiveDecryptFormat.m4a, _LiveDecryptFormat.flac];
    }
    return const [_LiveDecryptFormat.flac, _LiveDecryptFormat.m4a];
  }

  static Future<LiveDecryptedStreamResult?> _tryStartLiveDecryptAttempt({
    required String inputUrl,
    required String decryptionKey,
    required _LiveDecryptFormat format,
  }) async {
    final port = await _allocateLoopbackPort();
    final ext = format == _LiveDecryptFormat.flac ? 'flac' : 'm4a';
    final mimeType = format == _LiveDecryptFormat.flac
        ? 'audio/flac'
        : 'audio/mp4';
    final localUrl = 'http://localhost:$port/stream.$ext';

    final commandArguments = <String>[
      '-nostdin',
      '-hide_banner',
      '-loglevel',
      'error',
      '-decryption_key',
      decryptionKey,
      '-i',
      inputUrl,
      '-map',
      '0:a:0',
      '-c:a',
      'copy',
      if (format == _LiveDecryptFormat.flac) ...['-f', 'flac'],
      if (format == _LiveDecryptFormat.m4a) ...[
        '-movflags',
        '+frag_keyframe+empty_moov+default_base_moof',
        '-f',
        'mp4',
      ],
      '-content_type',
      mimeType,
      '-listen',
      '1',
      localUrl,
    ];

    _log.d(
      'Starting live decrypt tunnel: ${_previewCommandForLog(commandArguments.join(' '))}',
    );

    final session = await FFmpegKit.executeWithArgumentsAsync(commandArguments);
    await Future<void>.delayed(const Duration(milliseconds: 700));

    final state = await session.getState();
    if (state == SessionState.running || state == SessionState.created) {
      return LiveDecryptedStreamResult(
        localUrl: localUrl,
        format: ext,
        session: session,
      );
    }

    final output = (await session.getOutput() ?? '').trim();
    if (output.isNotEmpty) {
      _log.w('Live decrypt attempt failed ($ext): $output');
    }

    try {
      await session.cancel();
    } catch (_) {}
    return null;
  }

  static Future<int> _allocateLoopbackPort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  static Future<String?> convertFlacToOpus(
    String inputPath, {
    String bitrate = '128k',
    bool deleteOriginal = true,
  }) async {
    final outputPath = _buildOutputPath(inputPath, '.opus');

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

  static Future<String?> convertFlacToLossy(
    String inputPath, {
    required String format,
    String? bitrate,
    bool deleteOriginal = true,
  }) async {
    String bitrateValue = '320k';
    if (bitrate != null && bitrate.contains('_')) {
      final parts = bitrate.split('_');
      if (parts.length == 2) {
        bitrateValue = '${parts[1]}k';
      }
    }

    switch (format.toLowerCase()) {
      case 'opus':
        final opusBitrate = bitrate?.startsWith('opus_') == true
            ? bitrateValue
            : '128k';
        return convertFlacToOpus(
          inputPath,
          bitrate: opusBitrate,
          deleteOriginal: deleteOriginal,
        );
      case 'mp3':
      default:
        final mp3Bitrate = bitrate?.startsWith('mp3_') == true
            ? bitrateValue
            : '320k';
        return convertFlacToMp3(
          inputPath,
          bitrate: mp3Bitrate,
          deleteOriginal: deleteOriginal,
        );
    }
  }

  static Future<String?> convertFlacToM4a(
    String inputPath, {
    String codec = 'aac',
    String bitrate = '256k',
  }) async {
    final dir = File(inputPath).parent.path;
    final baseName = inputPath
        .split(Platform.pathSeparator)
        .last
        .replaceAll('.flac', '');
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
    final tempOutput = _nextTempEmbedPath(tempDir.path, '.flac');

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
    _log.d('Executing FFmpeg command: ${_previewCommandForLog(command)}');

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
    final tempOutput = _nextTempEmbedPath(tempDir.path, '.mp3');

    final StringBuffer cmdBuffer = StringBuffer();
    cmdBuffer.write('-i "$mp3Path" ');

    if (coverPath != null) {
      cmdBuffer.write('-i "$coverPath" ');
    }

    cmdBuffer.write('-map 0:a ');
    cmdBuffer.write('-map_metadata -1 ');

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
    _log.d(
      'Executing FFmpeg MP3 embed command: ${_previewCommandForLog(command)}',
    );

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

  static Future<String?> embedMetadataToOpus({
    required String opusPath,
    String? coverPath,
    Map<String, String>? metadata,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempOutput = _nextTempEmbedPath(tempDir.path, '.opus');

    final StringBuffer cmdBuffer = StringBuffer();
    cmdBuffer.write('-i "$opusPath" ');
    cmdBuffer.write('-map 0:a ');
    cmdBuffer.write('-map_metadata -1 ');
    cmdBuffer.write('-map_metadata:s:a -1 ');
    cmdBuffer.write('-c:a copy ');

    if (metadata != null) {
      metadata.forEach((key, value) {
        final sanitizedValue = value.replaceAll('"', '\\"');
        cmdBuffer.write('-metadata $key="$sanitizedValue" ');
      });
    }

    if (coverPath != null) {
      try {
        final pictureBlock = await _createMetadataBlockPicture(coverPath);
        if (pictureBlock != null) {
          final escapedBlock = pictureBlock.replaceAll('"', '\\"');
          cmdBuffer.write('-metadata METADATA_BLOCK_PICTURE="$escapedBlock" ');
          _log.d(
            'Created METADATA_BLOCK_PICTURE for Opus (${pictureBlock.length} chars)',
          );
        } else {
          _log.w('Failed to create METADATA_BLOCK_PICTURE, skipping cover');
        }
      } catch (e) {
        _log.e('Error creating METADATA_BLOCK_PICTURE: $e');
      }
    }

    cmdBuffer.write('"$tempOutput" -y');

    final command = cmdBuffer.toString();
    _log.d('Executing FFmpeg Opus embed command');

    final result = await _execute(command);

    if (result.success) {
      try {
        final tempFile = File(tempOutput);
        final originalFile = File(opusPath);

        if (await tempFile.exists()) {
          if (await originalFile.exists()) {
            await originalFile.delete();
          }
          await tempFile.copy(opusPath);
          await tempFile.delete();

          _log.d('Opus metadata embedded successfully');
          return opusPath;
        } else {
          _log.e('Temp Opus output file not found: $tempOutput');
          return null;
        }
      } catch (e) {
        _log.e('Failed to replace Opus file after metadata embed: $e');
        return null;
      }
    }

    try {
      final tempFile = File(tempOutput);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      _log.w('Failed to cleanup temp Opus file: $e');
    }

    _log.e('Opus Metadata embed failed: ${result.output}');
    return null;
  }

  static Future<String?> _createMetadataBlockPicture(String imagePath) async {
    try {
      final file = File(imagePath);
      if (!await file.exists()) {
        _log.e('Cover image not found: $imagePath');
        return null;
      }

      final imageData = await file.readAsBytes();

      String mimeType;
      if (imagePath.toLowerCase().endsWith('.png')) {
        mimeType = 'image/png';
      } else if (imagePath.toLowerCase().endsWith('.jpg') ||
          imagePath.toLowerCase().endsWith('.jpeg')) {
        mimeType = 'image/jpeg';
      } else {
        if (imageData.length >= 8 &&
            imageData[0] == 0x89 &&
            imageData[1] == 0x50 &&
            imageData[2] == 0x4E &&
            imageData[3] == 0x47) {
          mimeType = 'image/png';
        } else if (imageData.length >= 2 &&
            imageData[0] == 0xFF &&
            imageData[1] == 0xD8) {
          mimeType = 'image/jpeg';
        } else {
          mimeType = 'image/jpeg';
        }
      }

      final mimeBytes = utf8.encode(mimeType);
      const description = '';
      final descBytes = utf8.encode(description);

      final blockSize =
          4 +
          4 +
          mimeBytes.length +
          4 +
          descBytes.length +
          4 +
          4 +
          4 +
          4 +
          4 +
          imageData.length;

      final buffer = ByteData(blockSize);
      var offset = 0;

      buffer.setUint32(offset, 3, Endian.big);
      offset += 4;

      buffer.setUint32(offset, mimeBytes.length, Endian.big);
      offset += 4;

      final blockBytes = Uint8List(blockSize);
      blockBytes.setRange(0, offset, buffer.buffer.asUint8List());
      blockBytes.setRange(offset, offset + mimeBytes.length, mimeBytes);
      offset += mimeBytes.length;

      final tempBuffer = ByteData(4);
      tempBuffer.setUint32(0, descBytes.length, Endian.big);
      blockBytes.setRange(offset, offset + 4, tempBuffer.buffer.asUint8List());
      offset += 4;

      blockBytes.setRange(offset, offset + descBytes.length, descBytes);
      offset += descBytes.length;

      tempBuffer.setUint32(0, 0, Endian.big);
      blockBytes.setRange(offset, offset + 4, tempBuffer.buffer.asUint8List());
      offset += 4;

      tempBuffer.setUint32(0, 0, Endian.big);
      blockBytes.setRange(offset, offset + 4, tempBuffer.buffer.asUint8List());
      offset += 4;

      tempBuffer.setUint32(0, 0, Endian.big);
      blockBytes.setRange(offset, offset + 4, tempBuffer.buffer.asUint8List());
      offset += 4;

      tempBuffer.setUint32(0, 0, Endian.big);
      blockBytes.setRange(offset, offset + 4, tempBuffer.buffer.asUint8List());
      offset += 4;

      tempBuffer.setUint32(0, imageData.length, Endian.big);
      blockBytes.setRange(offset, offset + 4, tempBuffer.buffer.asUint8List());
      offset += 4;

      blockBytes.setRange(offset, offset + imageData.length, imageData);

      final base64String = base64Encode(blockBytes);

      return base64String;
    } catch (e) {
      _log.e('Error creating METADATA_BLOCK_PICTURE: $e');
      return null;
    }
  }

  /// Unified audio format conversion with full metadata + cover preservation.
  /// Supports: FLAC/MP3/Opus -> MP3/Opus (any direction except same format).
  /// Returns the new file path on success, null on failure.
  static Future<String?> convertAudioFormat({
    required String inputPath,
    required String targetFormat,
    required String bitrate,
    required Map<String, String> metadata,
    String? coverPath,
    bool deleteOriginal = true,
  }) async {
    final format = targetFormat.toLowerCase();
    if (format != 'mp3' && format != 'opus') {
      _log.e('Unsupported target format: $targetFormat');
      return null;
    }

    final extension = format == 'opus' ? '.opus' : '.mp3';
    final outputPath = _buildOutputPath(inputPath, extension);

    // Step 1: Convert audio
    String command;
    if (format == 'opus') {
      command =
          '-i "$inputPath" -codec:a libopus -b:a $bitrate -vbr on -compression_level 10 -map 0:a "$outputPath" -y';
    } else {
      command =
          '-i "$inputPath" -codec:a libmp3lame -b:a $bitrate -map 0:a -id3v2_version 3 "$outputPath" -y';
    }

    _log.i(
      'Converting ${inputPath.split(Platform.pathSeparator).last} to $format @ $bitrate',
    );
    final result = await _execute(command);

    if (!result.success) {
      _log.e('Audio conversion failed: ${result.output}');
      return null;
    }

    // Step 2: Embed metadata + cover into the converted file.
    // Treat embed failure as conversion failure when metadata/cover was requested.
    final hasMetadata = metadata.values.any((v) => v.trim().isNotEmpty);
    final hasCover = coverPath != null && coverPath.trim().isNotEmpty;
    if (hasMetadata || hasCover) {
      String? embedResult;
      if (format == 'mp3') {
        embedResult = await embedMetadataToMp3(
          mp3Path: outputPath,
          coverPath: coverPath,
          metadata: metadata,
        );
      } else {
        embedResult = await embedMetadataToOpus(
          opusPath: outputPath,
          coverPath: coverPath,
          metadata: metadata,
        );
      }

      if (embedResult == null) {
        _log.e(
          'Metadata/Cover preservation failed, rolling back converted file',
        );
        try {
          final out = File(outputPath);
          if (await out.exists()) {
            await out.delete();
          }
        } catch (e) {
          _log.w('Failed to cleanup failed converted file: $e');
        }
        return null;
      }
    }

    // Step 3: Delete original if requested
    if (deleteOriginal) {
      try {
        await File(inputPath).delete();
        _log.i(
          'Deleted original: ${inputPath.split(Platform.pathSeparator).last}',
        );
      } catch (e) {
        _log.w('Failed to delete original: $e');
      }
    }

    return outputPath;
  }

  static Map<String, String> _convertToId3Tags(
    Map<String, String> vorbisMetadata,
  ) {
    final id3Map = <String, String>{};

    for (final entry in vorbisMetadata.entries) {
      final key = entry.key.toUpperCase();
      final value = entry.value;

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
        case 'COMPOSER':
          id3Map['composer'] = value;
          break;
        case 'COMMENT':
          id3Map['comment'] = value;
          break;
        default:
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

enum _LiveDecryptFormat { flac, m4a }

class LiveDecryptedStreamResult {
  final String localUrl;
  final String format;
  final FFmpegSession session;

  LiveDecryptedStreamResult({
    required this.localUrl,
    required this.format,
    required this.session,
  });
}
