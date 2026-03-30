import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new_full/ffmpeg_session.dart';
import 'package:ffmpeg_kit_flutter_new_full/return_code.dart';
import 'package:ffmpeg_kit_flutter_new_full/session_state.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/utils/artist_utils.dart';
import 'package:spotiflac_android/utils/logger.dart';

final _log = AppLogger('FFmpeg');

class FFmpegService {
  static const int _commandLogPreviewLength = 300;
  static const Duration _liveTunnelStartupTimeout = Duration(seconds: 8);
  static const Duration _liveTunnelStartupPollInterval = Duration(
    milliseconds: 200,
  );
  static const Duration _liveTunnelStabilizationDelay = Duration(
    milliseconds: 900,
  );
  static int _tempEmbedCounter = 0;
  static FFmpegSession? _activeLiveDecryptSession;
  static String? _activeLiveDecryptUrl;
  static String? _activeLiveTempInputPath;
  static String? _activeNativeDashManifestPath;
  static String? _activeNativeDashManifestUrl;
  static final Set<String> _preparedNativeDashManifestPaths = <String>{};

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

  static Future<FFmpegResult> _executeWithArguments(
    List<String> arguments,
  ) async {
    try {
      final session = await FFmpegKit.executeWithArguments(arguments);
      final returnCode = await session.getReturnCode();
      final output = await session.getOutput() ?? '';

      return FFmpegResult(
        success: ReturnCode.isSuccess(returnCode),
        returnCode: returnCode?.getValue() ?? -1,
        output: output,
      );
    } catch (e) {
      _log.e('FFmpeg executeWithArguments error: $e');
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

    // Encrypted streams are commonly MP4 container with FLAC audio.
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
      // Force MOV demuxer: -decryption_key is only supported by the MOV/MP4
      // demuxer. The input may carry a .flac extension (SAF mode) while actually
      // containing an encrypted M4A stream, so we must override auto-detection.
      return '-v error -decryption_key "$key" -f mov -i "$inputPath" $audioMap-c copy "$outputPath" -y';
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

  static bool isActiveNativeDashManifestUrl(String url) {
    final activeUrl = _activeNativeDashManifestUrl;
    if (activeUrl == null || activeUrl.isEmpty) return false;

    final normalized = url.trim();
    if (activeUrl == normalized) return true;

    try {
      final activePath = Uri.parse(activeUrl).toFilePath();
      final incomingPath = Uri.parse(normalized).toFilePath();
      return activePath == incomingPath;
    } catch (_) {
      return false;
    }
  }

  static Future<String?> prepareTidalDashManifestForNativePlayback({
    required String manifestPayload,
    bool registerAsActive = true,
  }) async {
    final rawPayload = manifestPayload.trim();
    if (rawPayload.isEmpty) return null;

    final payload = rawPayload.startsWith('MANIFEST:')
        ? rawPayload.substring('MANIFEST:'.length)
        : rawPayload;

    final manifestPath = await _writeTempManifestFile(payload);
    if (manifestPath == null) {
      _log.e('Failed to prepare Tidal DASH manifest for native playback');
      return null;
    }

    final manifestUrl = Uri.file(manifestPath).toString();
    _preparedNativeDashManifestPaths.add(manifestPath);
    if (registerAsActive) {
      await activatePreparedNativeDashManifest(manifestUrl);
    }
    return manifestUrl;
  }

  static Future<void> activatePreparedNativeDashManifest(String url) async {
    final normalized = url.trim();
    if (normalized.isEmpty) return;

    final manifestPath = _nativeDashManifestPathFromUrl(normalized);
    if (manifestPath == null ||
        !_preparedNativeDashManifestPaths.contains(manifestPath)) {
      return;
    }

    final previousPath = _activeNativeDashManifestPath;
    _activeNativeDashManifestPath = manifestPath;
    _activeNativeDashManifestUrl = Uri.file(manifestPath).toString();

    if (previousPath != null &&
        previousPath.isNotEmpty &&
        previousPath != manifestPath) {
      _preparedNativeDashManifestPaths.remove(previousPath);
      await _deleteNativeDashManifestFile(previousPath);
    }
  }

  static Future<void> stopNativeDashManifestPlayback() async {
    final manifestPath = _activeNativeDashManifestPath;
    _activeNativeDashManifestPath = null;
    _activeNativeDashManifestUrl = null;

    if (manifestPath == null || manifestPath.isEmpty) return;
    _preparedNativeDashManifestPaths.remove(manifestPath);
    await _deleteNativeDashManifestFile(manifestPath);
  }

  static Future<void> cleanupInactivePreparedNativeDashManifests() async {
    final activePath = _activeNativeDashManifestPath;
    final stalePaths = _preparedNativeDashManifestPaths
        .where((path) => path != activePath)
        .toList(growable: false);

    for (final path in stalePaths) {
      _preparedNativeDashManifestPaths.remove(path);
      await _deleteNativeDashManifestFile(path);
    }
  }

  static String? _nativeDashManifestPathFromUrl(String url) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme.toLowerCase() != 'file') {
        return null;
      }
      final path = uri.toFilePath();
      return path.trim().isEmpty ? null : path;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _deleteNativeDashManifestFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
  }

  static Future<void> stopLiveDecryptedStream() async {
    final session = _activeLiveDecryptSession;
    final tempInputPath = _activeLiveTempInputPath;
    _activeLiveDecryptSession = null;
    _activeLiveDecryptUrl = null;
    _activeLiveTempInputPath = null;

    if (session != null) {
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

    if (tempInputPath != null && tempInputPath.isNotEmpty) {
      try {
        final file = File(tempInputPath);
        if (await file.exists()) {
          await file.delete();
        }
      } catch (_) {}
    }
  }

  static Future<LiveDecryptedStreamResult?> startTidalDashLiveStream({
    required String manifestPayload,
    String preferredFormat = 'm4a',
  }) async {
    final rawPayload = manifestPayload.trim();
    if (rawPayload.isEmpty) return null;

    final payload = rawPayload.startsWith('MANIFEST:')
        ? rawPayload.substring('MANIFEST:'.length)
        : rawPayload;

    final manifestPath = await _writeTempManifestFile(payload);
    if (manifestPath == null) {
      _log.e('Failed to prepare Tidal DASH manifest for live stream');
      return null;
    }

    await stopLiveDecryptedStream();
    await stopNativeDashManifestPlayback();

    final attempts = _buildLiveDashFormatAttempts(preferredFormat);
    for (final format in attempts) {
      final stream = await _tryStartLiveDashAttempt(
        manifestPath: manifestPath,
        format: format,
      );
      if (stream != null) {
        _activeLiveDecryptSession = stream.session;
        _activeLiveDecryptUrl = stream.localUrl;
        _activeLiveTempInputPath = manifestPath;
        return stream;
      }
    }

    try {
      final file = File(manifestPath);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (_) {}
    return null;
  }

  static Future<String?> _writeTempManifestFile(String payload) async {
    if (payload.trim().isEmpty) return null;

    Uint8List bytes;
    try {
      bytes = base64Decode(payload);
    } catch (_) {
      bytes = Uint8List.fromList(utf8.encode(payload));
    }

    final manifestText = utf8.decode(bytes, allowMalformed: true).trim();
    if (manifestText.isEmpty) return null;

    final tempDir = await getTemporaryDirectory();
    final manifestPath =
        '${tempDir.path}${Platform.pathSeparator}tidal_dash_${DateTime.now().microsecondsSinceEpoch}.mpd';
    await File(manifestPath).writeAsString(manifestText, flush: true);
    return manifestPath;
  }

  static List<_LiveDecryptFormat> _buildLiveDashFormatAttempts(
    String preferredFormat,
  ) {
    final normalized = preferredFormat.trim().toLowerCase();
    if (normalized == 'flac') {
      return const [_LiveDecryptFormat.flac, _LiveDecryptFormat.m4a];
    }
    return const [_LiveDecryptFormat.m4a, _LiveDecryptFormat.flac];
  }

  static Future<bool> _awaitLiveTunnelReady(FFmpegSession session) async {
    final deadline = DateTime.now().add(_liveTunnelStartupTimeout);
    var seenRunning = false;

    while (DateTime.now().isBefore(deadline)) {
      final state = await session.getState();
      if (state == SessionState.running) {
        seenRunning = true;
        break;
      }
      if (state != SessionState.created) {
        return false;
      }
      await Future<void>.delayed(_liveTunnelStartupPollInterval);
    }

    if (!seenRunning) {
      return false;
    }

    await Future<void>.delayed(_liveTunnelStabilizationDelay);
    return (await session.getState()) == SessionState.running;
  }

  static Future<LiveDecryptedStreamResult?> _tryStartLiveDashAttempt({
    required String manifestPath,
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
      '-protocol_whitelist',
      'file,http,https,tcp,tls,crypto,data',
      '-i',
      manifestPath,
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
      'Starting Tidal DASH tunnel: ${_previewCommandForLog(commandArguments.join(' '))}',
    );

    final session = await FFmpegKit.executeWithArgumentsAsync(commandArguments);
    final isReady = await _awaitLiveTunnelReady(session);
    if (isReady) {
      return LiveDecryptedStreamResult(
        localUrl: localUrl,
        format: ext,
        session: session,
      );
    }

    final state = await session.getState();
    final output = (await session.getOutput() ?? '').trim();
    if (output.isNotEmpty) {
      _log.w('Tidal DASH tunnel failed ($ext): $output');
    } else {
      _log.w('Tidal DASH tunnel failed ($ext) with session state: $state');
    }

    try {
      await session.cancel();
    } catch (_) {}
    return null;
  }

  static Future<LiveDecryptedStreamResult?> startEncryptedLiveDecryptedStream({
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
          _activeLiveTempInputPath = null;
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
    final isReady = await _awaitLiveTunnelReady(session);
    if (isReady) {
      return LiveDecryptedStreamResult(
        localUrl: localUrl,
        format: ext,
        session: session,
      );
    }

    final state = await session.getState();
    final output = (await session.getOutput() ?? '').trim();
    if (output.isNotEmpty) {
      _log.w('Live decrypt attempt failed ($ext): $output');
    } else {
      _log.w('Live decrypt attempt failed ($ext) with session state: $state');
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
    String artistTagMode = artistTagModeJoined,
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
      _appendVorbisMetadataToCommandBuffer(
        cmdBuffer,
        metadata,
        artistTagMode: artistTagMode,
      );
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
    String artistTagMode = artistTagModeJoined,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempOutput = _nextTempEmbedPath(tempDir.path, '.opus');
    final arguments = <String>[
      '-i',
      opusPath,
      '-map',
      '0:a',
      '-map_metadata',
      '-1',
      '-map_metadata:s:a',
      '-1',
      '-c:a',
      'copy',
    ];

    if (metadata != null) {
      _appendVorbisMetadataToArguments(
        arguments,
        metadata,
        artistTagMode: artistTagMode,
      );
    }

    if (coverPath != null) {
      try {
        final pictureBlock = await _createMetadataBlockPicture(coverPath);
        if (pictureBlock != null) {
          arguments
            ..add('-metadata')
            ..add('METADATA_BLOCK_PICTURE=$pictureBlock');
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

    arguments
      ..add(tempOutput)
      ..add('-y');
    _log.d('Executing FFmpeg Opus embed command');

    final result = await _executeWithArguments(arguments);

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

  static Future<String?> embedMetadataToM4a({
    required String m4aPath,
    String? coverPath,
    Map<String, String>? metadata,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempOutput = _nextTempEmbedPath(tempDir.path, '.m4a');

    final cmdBuffer = StringBuffer();
    cmdBuffer.write('-i "$m4aPath" ');

    final hasCover = coverPath != null && await File(coverPath).exists();
    if (hasCover) {
      cmdBuffer.write('-i "$coverPath" ');
    }

    cmdBuffer.write('-map 0:a ');
    cmdBuffer.write('-map_metadata -1 ');

    // For M4A/MP4, cover art is mapped as a video stream and stored in the
    // 'covr' atom automatically by FFmpeg. The '-disposition attached_pic'
    // flag is only valid for Matroska/WebM containers and must NOT be used here.
    if (hasCover) {
      cmdBuffer.write('-map 1:v -c:v copy ');
    }

    cmdBuffer.write('-c:a copy ');

    if (metadata != null) {
      final m4aMetadata = _convertToM4aTags(metadata);
      for (final entry in m4aMetadata.entries) {
        final sanitizedValue = entry.value.replaceAll('"', '\\"');
        cmdBuffer.write('-metadata ${entry.key}="$sanitizedValue" ');
      }
    }

    cmdBuffer.write('"$tempOutput" -y');

    final command = cmdBuffer.toString();
    _log.d(
      'Executing FFmpeg M4A embed command: ${_previewCommandForLog(command)}',
    );

    final result = await _execute(command);

    if (result.success) {
      try {
        final tempFile = File(tempOutput);
        final originalFile = File(m4aPath);

        if (await tempFile.exists()) {
          if (await originalFile.exists()) {
            await originalFile.delete();
          }
          await tempFile.copy(m4aPath);
          await tempFile.delete();

          _log.d('M4A metadata embedded successfully');
          return m4aPath;
        } else {
          _log.e('Temp M4A output file not found: $tempOutput');
          return null;
        }
      } catch (e) {
        _log.e('Failed to replace M4A file after metadata embed: $e');
        return null;
      }
    }

    try {
      final tempFile = File(tempOutput);
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    } catch (e) {
      _log.w('Failed to cleanup temp M4A file: $e');
    }

    _log.e('M4A Metadata embed failed: ${result.output}');
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
  /// Supports: FLAC/M4A/MP3/Opus -> MP3/Opus/ALAC/FLAC.
  /// ALAC and FLAC targets are lossless (bitrate parameter is ignored).
  /// Returns the new file path on success, null on failure.
  static Future<String?> convertAudioFormat({
    required String inputPath,
    required String targetFormat,
    required String bitrate,
    required Map<String, String> metadata,
    String? coverPath,
    String artistTagMode = artistTagModeJoined,
    bool deleteOriginal = true,
  }) async {
    final format = targetFormat.toLowerCase();
    if (!const {'mp3', 'opus', 'alac', 'flac'}.contains(format)) {
      _log.e('Unsupported target format: $targetFormat');
      return null;
    }

    // Lossless targets: dedicated single-pass methods
    if (format == 'alac') {
      return _convertToAlac(
        inputPath: inputPath,
        metadata: metadata,
        coverPath: coverPath,
        deleteOriginal: deleteOriginal,
      );
    }
    if (format == 'flac') {
      return _convertToFlac(
        inputPath: inputPath,
        metadata: metadata,
        coverPath: coverPath,
        artistTagMode: artistTagMode,
        deleteOriginal: deleteOriginal,
      );
    }

    // Lossy targets: MP3 / Opus
    final extension = format == 'opus' ? '.opus' : '.mp3';
    final outputPath = _buildOutputPath(inputPath, extension);

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
          artistTagMode: artistTagMode,
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

  /// Convert any audio format to ALAC (Apple Lossless) in an M4A container.
  /// Metadata and cover art are embedded in a single FFmpeg pass.
  static Future<String?> _convertToAlac({
    required String inputPath,
    required Map<String, String> metadata,
    String? coverPath,
    bool deleteOriginal = true,
  }) async {
    final outputPath = _buildOutputPath(inputPath, '.m4a');

    final cmdBuffer = StringBuffer();
    cmdBuffer.write('-i "$inputPath" ');

    final hasCover =
        coverPath != null &&
        coverPath.trim().isNotEmpty &&
        await File(coverPath).exists();
    if (hasCover) {
      cmdBuffer.write('-i "$coverPath" ');
    }

    cmdBuffer.write('-map 0:a ');
    if (hasCover) {
      cmdBuffer.write('-map 1:v -c:v copy -disposition:v:0 attached_pic ');
      cmdBuffer.write('-metadata:s:v title="Album cover" ');
      cmdBuffer.write('-metadata:s:v comment="Cover (front)" ');
    }
    cmdBuffer.write('-c:a alac ');
    cmdBuffer.write('-map_metadata -1 ');

    final m4aTags = _convertToM4aTags(metadata);
    for (final entry in m4aTags.entries) {
      final sanitized = entry.value.replaceAll('"', '\\"');
      cmdBuffer.write('-metadata ${entry.key}="$sanitized" ');
    }

    cmdBuffer.write('"$outputPath" -y');

    _log.i(
      'Converting ${inputPath.split(Platform.pathSeparator).last} to ALAC',
    );
    final result = await _execute(cmdBuffer.toString());

    if (!result.success) {
      _log.e('ALAC conversion failed: ${result.output}');
      return null;
    }

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

  /// Convert any audio format to FLAC with metadata and cover art preservation.
  static Future<String?> _convertToFlac({
    required String inputPath,
    required Map<String, String> metadata,
    String? coverPath,
    String artistTagMode = artistTagModeJoined,
    bool deleteOriginal = true,
  }) async {
    final outputPath = _buildOutputPath(inputPath, '.flac');

    final cmdBuffer = StringBuffer();
    cmdBuffer.write('-i "$inputPath" ');

    final hasCover =
        coverPath != null &&
        coverPath.trim().isNotEmpty &&
        await File(coverPath).exists();
    if (hasCover) {
      cmdBuffer.write('-i "$coverPath" ');
    }

    cmdBuffer.write('-map 0:a ');
    if (hasCover) {
      cmdBuffer.write('-map 1:v -c:v copy -disposition:v:0 attached_pic ');
      cmdBuffer.write('-metadata:s:v title="Album cover" ');
      cmdBuffer.write('-metadata:s:v comment="Cover (front)" ');
    }
    cmdBuffer.write('-c:a flac -compression_level 8 ');
    cmdBuffer.write('-map_metadata 0 ');

    _appendVorbisMetadataToCommandBuffer(
      cmdBuffer,
      metadata,
      artistTagMode: artistTagMode,
    );

    cmdBuffer.write('"$outputPath" -y');

    _log.i(
      'Converting ${inputPath.split(Platform.pathSeparator).last} to FLAC',
    );
    final result = await _execute(cmdBuffer.toString());

    if (!result.success) {
      _log.e('FLAC conversion failed: ${result.output}');
      return null;
    }

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

  /// Normalize metadata keys to standard Vorbis comment names, filtering out
  /// technical fields (bit_depth, sample_rate, duration, etc.).
  static Map<String, String> _normalizeToVorbisComments(
    Map<String, String> metadata,
  ) {
    final vorbis = <String, String>{};

    for (final entry in metadata.entries) {
      final key = entry.key.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final value = entry.value;
      if (value.trim().isEmpty) continue;

      switch (key) {
        case 'TITLE':
          vorbis['TITLE'] = value;
          break;
        case 'ARTIST':
          vorbis['ARTIST'] = value;
          break;
        case 'ALBUM':
          vorbis['ALBUM'] = value;
          break;
        case 'ALBUMARTIST':
          vorbis['ALBUMARTIST'] = value;
          break;
        case 'TRACKNUMBER':
        case 'TRACKNBR':
        case 'TRACK':
        case 'TRCK':
          if (value != '0') vorbis['TRACKNUMBER'] = value;
          break;
        case 'DISCNUMBER':
        case 'DISC':
        case 'TPOS':
          if (value != '0') vorbis['DISCNUMBER'] = value;
          break;
        case 'DATE':
        case 'YEAR':
          vorbis['DATE'] = value;
          break;
        case 'GENRE':
          vorbis['GENRE'] = value;
          break;
        case 'ISRC':
          vorbis['ISRC'] = value;
          break;
        case 'LABEL':
        case 'ORGANIZATION':
          vorbis['ORGANIZATION'] = value;
          break;
        case 'COPYRIGHT':
          vorbis['COPYRIGHT'] = value;
          break;
        case 'COMPOSER':
          vorbis['COMPOSER'] = value;
          break;
        case 'COMMENT':
          vorbis['COMMENT'] = value;
          break;
        case 'LYRICS':
        case 'UNSYNCEDLYRICS':
          vorbis['LYRICS'] = value;
          vorbis['UNSYNCEDLYRICS'] = value;
          break;
      }
    }

    return vorbis;
  }

  static void _appendVorbisMetadataToCommandBuffer(
    StringBuffer cmdBuffer,
    Map<String, String> metadata, {
    String artistTagMode = artistTagModeJoined,
  }) {
    for (final entry in _buildVorbisMetadataEntries(
      metadata,
      artistTagMode: artistTagMode,
    )) {
      final sanitized = entry.value.replaceAll('"', '\\"');
      cmdBuffer.write('-metadata ${entry.key}="$sanitized" ');
    }
  }

  static void _appendVorbisMetadataToArguments(
    List<String> arguments,
    Map<String, String> metadata, {
    String artistTagMode = artistTagModeJoined,
  }) {
    for (final entry in _buildVorbisMetadataEntries(
      metadata,
      artistTagMode: artistTagMode,
    )) {
      arguments
        ..add('-metadata')
        ..add('${entry.key}=${entry.value}');
    }
  }

  static List<MapEntry<String, String>> _buildVorbisMetadataEntries(
    Map<String, String> metadata, {
    String artistTagMode = artistTagModeJoined,
  }) {
    final vorbis = _normalizeToVorbisComments(metadata);
    final entries = <MapEntry<String, String>>[];

    for (final entry in vorbis.entries) {
      if (entry.key == 'ARTIST' || entry.key == 'ALBUMARTIST') {
        continue;
      }
      entries.add(entry);
    }

    _appendVorbisArtistEntries(
      entries,
      'ARTIST',
      vorbis['ARTIST'],
      artistTagMode: artistTagMode,
    );
    _appendVorbisArtistEntries(
      entries,
      'ALBUMARTIST',
      vorbis['ALBUMARTIST'],
      artistTagMode: artistTagMode,
    );

    return entries;
  }

  static void _appendVorbisArtistEntries(
    List<MapEntry<String, String>> entries,
    String key,
    String? rawValue, {
    String artistTagMode = artistTagModeJoined,
  }) {
    final value = rawValue?.trim() ?? '';
    if (value.isEmpty) {
      return;
    }

    if (!shouldSplitVorbisArtistTags(artistTagMode)) {
      entries.add(MapEntry(key, value));
      return;
    }

    for (final artist in splitArtistTagValues(value)) {
      entries.add(MapEntry(key, artist));
    }
  }

  /// Map Vorbis comment keys to M4A/MP4 metadata tag names for FFmpeg.
  static Map<String, String> _convertToM4aTags(Map<String, String> metadata) {
    final m4aMap = <String, String>{};

    for (final entry in metadata.entries) {
      final key = entry.key.toUpperCase().replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final value = entry.value;
      if (value.trim().isEmpty) continue;

      switch (key) {
        case 'TITLE':
          m4aMap['title'] = value;
          break;
        case 'ARTIST':
          m4aMap['artist'] = value;
          break;
        case 'ALBUM':
          m4aMap['album'] = value;
          break;
        case 'ALBUMARTIST':
          m4aMap['album_artist'] = value;
          break;
        case 'TRACKNUMBER':
        case 'TRACK':
        case 'TRCK':
          m4aMap['track'] = value;
          break;
        case 'DISCNUMBER':
        case 'DISC':
        case 'TPOS':
          m4aMap['disc'] = value;
          break;
        case 'DATE':
        case 'YEAR':
          m4aMap['date'] = value;
          break;
        case 'GENRE':
          m4aMap['genre'] = value;
          break;
        case 'ISRC':
          m4aMap['isrc'] = value;
          break;
        case 'COMPOSER':
          m4aMap['composer'] = value;
          break;
        case 'COMMENT':
          m4aMap['comment'] = value;
          break;
        case 'COPYRIGHT':
          m4aMap['copyright'] = value;
          break;
        case 'LABEL':
        case 'ORGANIZATION':
          m4aMap['organization'] = value;
          break;
        case 'LYRICS':
        case 'UNSYNCEDLYRICS':
          m4aMap['lyrics'] = value;
          break;
      }
    }

    return m4aMap;
  }

  static Map<String, String> _convertToId3Tags(
    Map<String, String> vorbisMetadata,
  ) {
    final id3Map = <String, String>{};

    for (final entry in vorbisMetadata.entries) {
      final key = entry.key.toUpperCase();
      final normalizedKey = key.replaceAll(RegExp(r'[^A-Z0-9]'), '');
      final value = entry.value;
      if (value.trim().isEmpty) {
        continue;
      }

      switch (normalizedKey) {
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
        case 'TRCK':
          if (value != '0') {
            id3Map['track'] = value;
          }
          break;
        case 'DISCNUMBER':
        case 'DISC':
        case 'TPOS':
          if (value != '0') {
            id3Map['disc'] = value;
          }
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

  /// Split a CUE+audio file into individual track files using FFmpeg.
  /// Each track is extracted with `-c copy` (no re-encoding) and metadata is embedded.
  /// [audioPath] is the source audio file (FLAC, WAV, etc.)
  /// [outputDir] is where individual track files will be saved
  /// [tracks] is the list of track split info from the Go CUE parser
  /// [albumMetadata] contains album-level metadata (artist, album, genre, date)
  /// Returns list of output file paths on success, null on failure.
  static Future<List<String>?> splitCueToTracks({
    required String audioPath,
    required String outputDir,
    required List<CueSplitTrackInfo> tracks,
    required Map<String, String> albumMetadata,
    String? coverPath,
    void Function(int current, int total)? onProgress,
  }) async {
    if (tracks.isEmpty) {
      _log.e('No tracks to split');
      return null;
    }

    final outputPaths = <String>[];
    final inputExt = audioPath.toLowerCase().split('.').last;
    final outputExt =
        (inputExt == 'flac' ||
            inputExt == 'wav' ||
            inputExt == 'ape' ||
            inputExt == 'wv')
        ? 'flac'
        : inputExt;

    for (var i = 0; i < tracks.length; i++) {
      final track = tracks[i];
      onProgress?.call(i + 1, tracks.length);

      final sanitizedTitle = track.title
          .replaceAll(RegExp(r'[<>:"/\\|?*]'), '_')
          .replaceAll(RegExp(r'\s+'), ' ')
          .trim();
      final trackNumStr = track.number.toString().padLeft(2, '0');
      final outputFileName = '$trackNumStr - $sanitizedTitle.$outputExt';
      final outputPath = '$outputDir${Platform.pathSeparator}$outputFileName';

      final StringBuffer cmdBuffer = StringBuffer();
      cmdBuffer.write('-i "$audioPath" ');

      final startTime = _formatSecondsForFFmpeg(track.startSec);
      cmdBuffer.write('-ss $startTime ');

      if (track.endSec > 0) {
        final endTime = _formatSecondsForFFmpeg(track.endSec);
        cmdBuffer.write('-to $endTime ');
      }

      if (outputExt == 'flac') {
        cmdBuffer.write('-c:a flac -compression_level 8 ');
      } else {
        cmdBuffer.write('-c:a copy ');
      }

      final artist = track.artist.isNotEmpty
          ? track.artist
          : (albumMetadata['artist'] ?? '');
      final album = albumMetadata['album'] ?? '';
      final genre = albumMetadata['genre'] ?? '';
      final date = albumMetadata['date'] ?? '';

      void addMeta(String key, String value) {
        if (value.isNotEmpty) {
          final sanitized = value.replaceAll('"', '\\"');
          cmdBuffer.write('-metadata $key="$sanitized" ');
        }
      }

      addMeta('TITLE', track.title);
      addMeta('ARTIST', artist);
      addMeta('ALBUM', album);
      addMeta('ALBUMARTIST', albumMetadata['artist'] ?? '');
      addMeta('TRACKNUMBER', track.number.toString());
      addMeta('GENRE', genre);
      addMeta('DATE', date);
      if (track.isrc.isNotEmpty) addMeta('ISRC', track.isrc);
      if (track.composer.isNotEmpty) addMeta('COMPOSER', track.composer);

      cmdBuffer.write('"$outputPath" -y');

      final command = cmdBuffer.toString();
      _log.d(
        'CUE split track ${track.number}: ${_previewCommandForLog(command)}',
      );

      final result = await _execute(command);
      if (!result.success) {
        _log.e('CUE split failed for track ${track.number}: ${result.output}');
        continue;
      }

      if (coverPath != null && coverPath.isNotEmpty && outputExt == 'flac') {}

      outputPaths.add(outputPath);
      _log.i('CUE split: track ${track.number} -> $outputFileName');
    }

    if (outputPaths.isEmpty) {
      _log.e('CUE split: no tracks were successfully extracted');
      return null;
    }

    _log.i('CUE split complete: ${outputPaths.length}/${tracks.length} tracks');
    return outputPaths;
  }

  static String _formatSecondsForFFmpeg(double seconds) {
    if (seconds < 0) return '0';
    final hours = seconds ~/ 3600;
    final mins = (seconds % 3600) ~/ 60;
    final secs = seconds - (hours * 3600) - (mins * 60);
    return '${hours.toString().padLeft(2, '0')}:${mins.toInt().toString().padLeft(2, '0')}:${secs.toStringAsFixed(3).padLeft(6, '0')}';
  }
}

/// Track info for CUE splitting, passed from the CUE parser
class CueSplitTrackInfo {
  final int number;
  final String title;
  final String artist;
  final String isrc;
  final String composer;
  final double startSec;
  final double endSec;

  CueSplitTrackInfo({
    required this.number,
    required this.title,
    required this.artist,
    this.isrc = '',
    this.composer = '',
    required this.startSec,
    required this.endSec,
  });

  factory CueSplitTrackInfo.fromJson(Map<String, dynamic> json) {
    return CueSplitTrackInfo(
      number: json['number'] as int? ?? 0,
      title: json['title'] as String? ?? '',
      artist: json['artist'] as String? ?? '',
      isrc: json['isrc'] as String? ?? '',
      composer: json['composer'] as String? ?? '',
      startSec: (json['start_sec'] as num?)?.toDouble() ?? 0.0,
      endSec: (json['end_sec'] as num?)?.toDouble() ?? -1.0,
    );
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
