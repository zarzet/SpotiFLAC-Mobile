import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
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

class DownloadDecryptionDescriptor {
  final String strategy;
  final String key;
  final String? iv;
  final String? inputFormat;
  final String? outputExtension;
  final Map<String, dynamic> options;

  const DownloadDecryptionDescriptor({
    required this.strategy,
    required this.key,
    this.iv,
    this.inputFormat,
    this.outputExtension,
    this.options = const {},
  });

  factory DownloadDecryptionDescriptor.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'];
    return DownloadDecryptionDescriptor(
      strategy: (json['strategy'] as String? ?? '').trim(),
      key: (json['key'] as String? ?? '').trim(),
      iv: (json['iv'] as String?)?.trim(),
      inputFormat: (json['input_format'] as String?)?.trim(),
      outputExtension: (json['output_extension'] as String?)?.trim(),
      options: rawOptions is Map
          ? Map<String, dynamic>.from(rawOptions)
          : const {},
    );
  }

  Map<String, dynamic> toJson() {
    final json = <String, dynamic>{'strategy': strategy, 'key': key};
    if (iv != null && iv!.isNotEmpty) {
      json['iv'] = iv;
    }
    if (inputFormat != null && inputFormat!.isNotEmpty) {
      json['input_format'] = inputFormat;
    }
    if (outputExtension != null && outputExtension!.isNotEmpty) {
      json['output_extension'] = outputExtension;
    }
    if (options.isNotEmpty) {
      json['options'] = options;
    }
    return json;
  }

  static DownloadDecryptionDescriptor? fromDownloadResult(
    Map<String, dynamic> result,
  ) {
    final rawDecryption = result['decryption'];
    if (rawDecryption is Map) {
      final descriptor = DownloadDecryptionDescriptor.fromJson(
        Map<String, dynamic>.from(rawDecryption),
      );
      if (descriptor.normalizedStrategy == 'ffmpeg.mov_key' &&
          descriptor.key.isNotEmpty) {
        return descriptor;
      }
    }

    final legacyKey = (result['decryption_key'] as String?)?.trim() ?? '';
    if (legacyKey.isEmpty) {
      return null;
    }

    return DownloadDecryptionDescriptor(
      strategy: 'ffmpeg.mov_key',
      key: legacyKey,
      inputFormat: 'mov',
    );
  }

  String get normalizedStrategy {
    switch (strategy.trim().toLowerCase()) {
      case '':
      case 'ffmpeg.mov_key':
      case 'ffmpeg_mov_key':
      case 'mov_decryption_key':
      case 'mp4_decryption_key':
      case 'ffmpeg.mp4_decryption_key':
        return 'ffmpeg.mov_key';
      default:
        return strategy.trim();
    }
  }
}

class FFmpegService {
  static const int _commandLogPreviewLength = 300;
  static const Duration _liveTunnelStartupTimeout = Duration(seconds: 8);
  static const Duration _liveTunnelStartupPollInterval = Duration(
    milliseconds: 200,
  );
  static const Duration _liveTunnelStabilizationDelay = Duration(
    milliseconds: 900,
  );
  static const String _genericMovKeyDecryptionStrategy = 'ffmpeg.mov_key';
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
          '-v error -hide_banner -i "$inputPath" -codec:a libopus -b:a $bitrateValue -vbr on -compression_level 10 -map 0:a "$outputPath" -y';
    } else {
      command =
          '-v error -hide_banner -i "$inputPath" -codec:a libmp3lame -b:a $bitrateValue -map 0:a -id3v2_version 3 "$outputPath" -y';
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
    return decryptWithDescriptor(
      inputPath: inputPath,
      descriptor: DownloadDecryptionDescriptor(
        strategy: _genericMovKeyDecryptionStrategy,
        key: decryptionKey,
        inputFormat: 'mov',
      ),
      deleteOriginal: deleteOriginal,
    );
  }

  static Future<String?> decryptWithDescriptor({
    required String inputPath,
    required DownloadDecryptionDescriptor descriptor,
    bool deleteOriginal = true,
  }) async {
    final key = descriptor.key.trim();

    switch (descriptor.normalizedStrategy) {
      case _genericMovKeyDecryptionStrategy:
        if (key.isEmpty) {
          return inputPath;
        }
        return _decryptMovKeyFile(
          inputPath: inputPath,
          decryptionKey: key,
          inputFormat: descriptor.inputFormat,
          outputExtension: descriptor.outputExtension,
          deleteOriginal: deleteOriginal,
        );
      default:
        _log.e(
          'Unsupported download decryption strategy: ${descriptor.strategy}',
        );
        return null;
    }
  }

  static String _resolvePreferredDecryptionExtension(
    String inputPath,
    String? requestedExtension,
  ) {
    final trimmedRequested = (requestedExtension ?? '').trim();
    if (trimmedRequested.isNotEmpty) {
      return trimmedRequested.startsWith('.')
          ? trimmedRequested
          : '.$trimmedRequested';
    }

    return inputPath.toLowerCase().endsWith('.m4a')
        ? '.flac'
        : inputPath.toLowerCase().endsWith('.flac')
        ? '.flac'
        : inputPath.toLowerCase().endsWith('.mp3')
        ? '.mp3'
        : inputPath.toLowerCase().endsWith('.opus')
        ? '.opus'
        : '.flac';
  }

  static Future<String?> _decryptMovKeyFile({
    required String inputPath,
    required String decryptionKey,
    String? inputFormat,
    String? outputExtension,
    bool deleteOriginal = true,
  }) async {
    final preferredExt = _resolvePreferredDecryptionExtension(
      inputPath,
      outputExtension,
    );
    var tempOutput = _buildOutputPath(inputPath, preferredExt);
    final demuxerFormat = (inputFormat ?? '').trim().isNotEmpty
        ? inputFormat!.trim()
        : 'mov';

    String buildDecryptCommand(
      String outputPath, {
      required bool mapAudioOnly,
      required String key,
    }) {
      final audioMap = mapAudioOnly ? '-map 0:a ' : '';
      // Force MOV demuxer: -decryption_key is only supported by the MOV/MP4
      // demuxer. The input may carry a .flac extension (SAF mode) while actually
      // containing an encrypted M4A stream, so we must override auto-detection.
      return '-v error -decryption_key "$key" -f $demuxerFormat -i "$inputPath" $audioMap-c copy "$outputPath" -y';
    }

    final keyCandidates = _buildDecryptionKeyCandidates(decryptionKey);
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
        '-v error -hide_banner -i "$inputPath" -codec:a libmp3lame -b:a $bitrate -map 0:a -map_metadata 0 -id3v2_version 3 "$outputPath" -y';

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
        '-v error -hide_banner -i "$inputPath" -codec:a libopus -b:a $bitrate -vbr on -compression_level 10 -map 0:a -map_metadata 0 "$outputPath" -y';

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
          '-v error -hide_banner -i "$inputPath" -codec:a alac -map 0:a -map_metadata 0 "$outputPath" -y';
    } else {
      command =
          '-v error -hide_banner -i "$inputPath" -codec:a aac -b:a $bitrate -map 0:a -map_metadata 0 "$outputPath" -y';
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

  /// Scan an audio file for EBU R128 loudness and compute ReplayGain values.
  ///
  /// Uses the FFmpeg `ebur128` audio filter to measure integrated loudness (LUFS)
  /// and true peak. ReplayGain reference level is -18 LUFS (≈ 89 dB SPL).
  ///
  /// Returns a [ReplayGainResult] on success, or null if the scan fails.
  static Future<ReplayGainResult?> scanReplayGain(String filePath) async {
    // -nostats suppresses the interactive progress line.
    // ebur128=peak=true prints integrated loudness + true peak.
    // framelog=quiet suppresses per-frame measurements (very verbose),
    // keeping only the final summary which we parse.
    final command =
        '-hide_banner -nostats -i "$filePath" -filter_complex ebur128=peak=true:framelog=quiet -f null -';

    _log.d(
      'Scanning ReplayGain for: ${filePath.split(Platform.pathSeparator).last}',
    );
    final result = await _execute(command);

    // FFmpeg writes ebur128 stats to stderr, which ends up in the output.
    // Even on "failure" return code, the output may contain valid data
    // because -f null always "fails" on some FFmpeg builds.
    final output = result.output;

    // Parse integrated loudness: "I:        -14.0 LUFS"
    final integratedMatch = RegExp(
      r'I:\s+(-?\d+\.?\d*)\s+LUFS',
    ).allMatches(output);
    if (integratedMatch.isEmpty) {
      _log.w('ReplayGain scan: could not parse integrated loudness');
      return null;
    }
    // Take the last match (the summary, not per-segment values)
    final integratedLufs = double.tryParse(integratedMatch.last.group(1) ?? '');
    if (integratedLufs == null) {
      _log.w('ReplayGain scan: invalid integrated loudness value');
      return null;
    }

    // Parse true peak: "Peak:      0.9 dBFS" or "True peak:\n    Peak:    -0.3 dBFS"
    // The ebur128 filter with peak=true outputs per-channel true peak.
    // We want the highest (maximum) true peak across all channels.
    double? truePeakDbfs;
    final peakMatches = RegExp(
      r'Peak:\s+(-?\d+\.?\d*)\s+dBFS',
    ).allMatches(output);
    for (final m in peakMatches) {
      final val = double.tryParse(m.group(1) ?? '');
      if (val != null) {
        if (truePeakDbfs == null || val > truePeakDbfs) {
          truePeakDbfs = val;
        }
      }
    }

    const replayGainReferenceLufs = -18.0;
    final gainDb = replayGainReferenceLufs - integratedLufs;

    // Convert true peak from dBFS to linear ratio.
    // If no true peak was found, fall back to 1.0 (0 dBFS).
    double peakLinear;
    if (truePeakDbfs != null) {
      peakLinear = math.pow(10, truePeakDbfs / 20.0).toDouble();
    } else {
      peakLinear = 1.0;
    }

    final trackGain =
        '${gainDb >= 0 ? "+" : ""}${gainDb.toStringAsFixed(2)} dB';
    final trackPeak = peakLinear.toStringAsFixed(6);

    _log.i(
      'ReplayGain scan result: gain=$trackGain, peak=$trackPeak (integrated=${integratedLufs.toStringAsFixed(1)} LUFS)',
    );

    return ReplayGainResult(
      trackGain: trackGain,
      trackPeak: trackPeak,
      integratedLufs: integratedLufs,
      truePeakLinear: peakLinear,
    );
  }

  /// Write album ReplayGain tags to a non-FLAC file (MP3/Opus) using FFmpeg.
  /// Preserves all existing metadata and adds/overwrites album gain fields.
  /// Write album ReplayGain tags to a file via FFmpeg.
  ///
  /// For local files, replaces the file in-place and returns `true`.
  /// When [returnTempPath] is `true` (for SAF content:// URIs), the method
  /// skips the file replacement and returns the temp output path as a String
  /// via [tempOutputPath].  The caller is responsible for writing the temp
  /// file to the SAF URI and cleaning it up.
  static Future<bool> writeAlbumReplayGainTags(
    String filePath,
    String albumGain,
    String albumPeak, {
    bool returnTempPath = false,
    void Function(String tempPath)? onTempReady,
  }) async {
    final ext = filePath.contains('.')
        ? '.${filePath.split('.').last}'
        : '.tmp';
    final tempDir = await getTemporaryDirectory();
    final tempOutput = _nextTempEmbedPath(tempDir.path, ext);
    final arguments = <String>[
      '-v',
      'error',
      '-hide_banner',
      '-i',
      filePath,
      '-map',
      '0',
      '-c',
      'copy',
      '-map_metadata',
      '0',
      '-metadata',
      'REPLAYGAIN_ALBUM_GAIN=$albumGain',
      '-metadata',
      'REPLAYGAIN_ALBUM_PEAK=$albumPeak',
      tempOutput,
      '-y',
    ];

    _log.d('Writing album ReplayGain tags via FFmpeg');
    final result = await _executeWithArguments(arguments);

    if (result.success) {
      try {
        final tempFile = File(tempOutput);
        if (await tempFile.exists()) {
          if (returnTempPath) {
            // Caller will handle SAF write-back and cleanup.
            onTempReady?.call(tempOutput);
            return true;
          }
          final originalFile = File(filePath);
          if (await originalFile.exists()) {
            await originalFile.delete();
          }
          await tempFile.copy(filePath);
          await tempFile.delete();
          _log.d('Album ReplayGain tags written successfully');
          return true;
        }
      } catch (e) {
        _log.w('Failed to replace file with album ReplayGain: $e');
      }
    }

    // Cleanup temp file on failure
    try {
      final tempFile = File(tempOutput);
      if (await tempFile.exists()) await tempFile.delete();
    } catch (_) {}

    return false;
  }

  static Future<String?> embedMetadata({
    required String flacPath,
    String? coverPath,
    Map<String, String>? metadata,
    String artistTagMode = artistTagModeJoined,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempOutput = _nextTempEmbedPath(tempDir.path, '.flac');
    final arguments = <String>['-v', 'error', '-hide_banner', '-i', flacPath];

    if (coverPath != null) {
      arguments
        ..add('-i')
        ..add(coverPath);
    }

    arguments
      ..add('-map')
      ..add('0:a');

    if (coverPath != null) {
      arguments
        ..add('-map')
        ..add('1:0')
        ..add('-c:v')
        ..add('copy')
        ..add('-disposition:v')
        ..add('attached_pic')
        ..add('-metadata:s:v')
        ..add('title=Album cover')
        ..add('-metadata:s:v')
        ..add('comment=Cover (front)');
    }

    arguments
      ..add('-c:a')
      ..add('copy');

    if (metadata != null) {
      _appendVorbisMetadataToArguments(
        arguments,
        metadata,
        artistTagMode: artistTagMode,
      );
    }

    arguments
      ..add(tempOutput)
      ..add('-y');

    _log.d('Executing FFmpeg FLAC embed command');
    final result = await _executeWithArguments(arguments);

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
    bool preserveMetadata = false,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempOutput = _nextTempEmbedPath(tempDir.path, '.mp3');
    final arguments = <String>['-v', 'error', '-hide_banner', '-i', mp3Path];

    if (coverPath != null) {
      arguments
        ..add('-i')
        ..add(coverPath);
    }

    arguments
      ..add('-map')
      ..add('0:a')
      ..add('-map_metadata')
      ..add(preserveMetadata ? '0' : '-1');

    if (coverPath != null) {
      arguments
        ..add('-map')
        ..add('1:0')
        ..add('-c:v:0')
        ..add('copy')
        ..add('-id3v2_version')
        ..add('3')
        ..add('-metadata:s:v')
        ..add('title=Album cover')
        ..add('-metadata:s:v')
        ..add('comment=Cover (front)');
    }

    arguments
      ..add('-c:a')
      ..add('copy');

    if (metadata != null) {
      _appendMappedMetadataToArguments(arguments, _convertToId3Tags(metadata));
    }

    arguments
      ..add('-id3v2_version')
      ..add('3')
      ..add(tempOutput)
      ..add('-y');

    _log.d('Executing FFmpeg MP3 embed command');
    final result = await _executeWithArguments(arguments);

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
    bool preserveMetadata = false,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempOutput = _nextTempEmbedPath(tempDir.path, '.opus');
    final mapMetaValue = preserveMetadata ? '0' : '-1';
    final arguments = <String>[
      '-v',
      'error',
      '-hide_banner',
      '-i',
      opusPath,
      '-map',
      '0:a',
      '-map_metadata',
      mapMetaValue,
      '-map_metadata:s:a',
      mapMetaValue,
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
    bool preserveMetadata = true,
  }) async {
    final tempDir = await getTemporaryDirectory();
    final tempOutput = _nextTempEmbedPath(tempDir.path, '.m4a');
    final arguments = <String>['-v', 'error', '-hide_banner', '-i', m4aPath];

    final normalizedCoverPath = coverPath?.trim();
    final hasCover =
        normalizedCoverPath != null &&
        normalizedCoverPath.isNotEmpty &&
        await File(normalizedCoverPath).exists();
    if (hasCover) {
      arguments
        ..add('-i')
        ..add(normalizedCoverPath);
    }

    final preserveExistingStreams = preserveMetadata && !hasCover;
    if (preserveExistingStreams) {
      // When no replacement cover is provided, preserve all input streams so
      // the existing attached artwork is not dropped during the metadata rewrite.
      arguments
        ..add('-map')
        ..add('0')
        ..add('-c')
        ..add('copy');
    } else {
      arguments
        ..add('-map')
        ..add('0:a')
        ..add('-c:a')
        ..add('copy');
    }
    arguments
      ..add('-map_metadata')
      ..add(preserveMetadata ? '0' : '-1');

    // For M4A cover replacements, mark the image as an attached picture so the
    // mp4 muxer writes a proper covr atom instead of a generic MJPEG video track.
    // Force the mp4 muxer because the default ipod muxer (auto-selected for .m4a)
    // does not register a codec tag for mjpeg on FFmpeg 8.0+.
    if (hasCover) {
      arguments
        ..add('-map')
        ..add('1:v')
        ..add('-c:v')
        ..add('copy')
        ..add('-disposition:v:0')
        ..add('attached_pic')
        ..add('-metadata:s:v')
        ..add('title=Album cover')
        ..add('-metadata:s:v')
        ..add('comment=Cover (front)')
        ..add('-f')
        ..add('mp4');
    }

    if (metadata != null) {
      _appendMappedMetadataToArguments(arguments, _convertToM4aTags(metadata));
    }

    arguments
      ..add(tempOutput)
      ..add('-y');

    _log.d('Executing FFmpeg M4A embed command');
    final result = await _executeWithArguments(arguments);

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

    final extension = format == 'opus' ? '.opus' : '.mp3';
    final outputPath = _buildOutputPath(inputPath, extension);

    String command;
    if (format == 'opus') {
      command =
          '-v error -hide_banner -i "$inputPath" -codec:a libopus -b:a $bitrate -vbr on -compression_level 10 -map 0:a "$outputPath" -y';
    } else {
      command =
          '-v error -hide_banner -i "$inputPath" -codec:a libmp3lame -b:a $bitrate -map 0:a -id3v2_version 3 "$outputPath" -y';
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
    final arguments = <String>['-v', 'error', '-hide_banner', '-i', inputPath];

    final hasCover =
        coverPath != null &&
        coverPath.trim().isNotEmpty &&
        await File(coverPath).exists();
    if (hasCover) {
      arguments
        ..add('-i')
        ..add(coverPath);
    }

    arguments
      ..add('-map')
      ..add('0:a');
    if (hasCover) {
      arguments
        ..add('-map')
        ..add('1:v')
        ..add('-c:v')
        ..add('copy')
        ..add('-disposition:v:0')
        ..add('attached_pic')
        ..add('-metadata:s:v')
        ..add('title=Album cover')
        ..add('-metadata:s:v')
        ..add('comment=Cover (front)');
    }
    arguments
      ..add('-c:a')
      ..add('alac')
      ..add('-map_metadata')
      ..add('-1');

    _appendMappedMetadataToArguments(arguments, _convertToM4aTags(metadata));

    arguments
      ..add(outputPath)
      ..add('-y');

    _log.i(
      'Converting ${inputPath.split(Platform.pathSeparator).last} to ALAC',
    );
    final result = await _executeWithArguments(arguments);

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
    final arguments = <String>['-v', 'error', '-hide_banner', '-i', inputPath];

    final hasCover =
        coverPath != null &&
        coverPath.trim().isNotEmpty &&
        await File(coverPath).exists();
    if (hasCover) {
      arguments
        ..add('-i')
        ..add(coverPath);
    }

    arguments
      ..add('-map')
      ..add('0:a');
    if (hasCover) {
      arguments
        ..add('-map')
        ..add('1:v')
        ..add('-c:v')
        ..add('copy')
        ..add('-disposition:v:0')
        ..add('attached_pic')
        ..add('-metadata:s:v')
        ..add('title=Album cover')
        ..add('-metadata:s:v')
        ..add('comment=Cover (front)');
    }
    arguments
      ..add('-c:a')
      ..add('flac')
      ..add('-compression_level')
      ..add('8')
      ..add('-map_metadata')
      ..add('0');

    _appendVorbisMetadataToArguments(
      arguments,
      metadata,
      artistTagMode: artistTagMode,
    );

    arguments
      ..add(outputPath)
      ..add('-y');

    _log.i(
      'Converting ${inputPath.split(Platform.pathSeparator).last} to FLAC',
    );
    final result = await _executeWithArguments(arguments);

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
          vorbis['DATE'] = value;
          final yearMatch = RegExp(r'^(\d{4})').firstMatch(value);
          if (yearMatch != null &&
              (!vorbis.containsKey('YEAR') || vorbis['YEAR']!.isEmpty)) {
            vorbis['YEAR'] = yearMatch.group(1)!;
          }
          break;
        case 'YEAR':
          vorbis['YEAR'] = value;
          if (!vorbis.containsKey('DATE') || vorbis['DATE']!.isEmpty) {
            vorbis['DATE'] = value;
          }
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
        case 'REPLAYGAINTRACKGAIN':
          vorbis['REPLAYGAIN_TRACK_GAIN'] = value;
          break;
        case 'REPLAYGAINTRACKPEAK':
          vorbis['REPLAYGAIN_TRACK_PEAK'] = value;
          break;
        case 'REPLAYGAINALBUMGAIN':
          vorbis['REPLAYGAIN_ALBUM_GAIN'] = value;
          break;
        case 'REPLAYGAINALBUMPEAK':
          vorbis['REPLAYGAIN_ALBUM_PEAK'] = value;
          break;
      }
    }

    return vorbis;
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

  static void _appendMappedMetadataToArguments(
    List<String> arguments,
    Map<String, String> metadata,
  ) {
    for (final entry in metadata.entries) {
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
    if (rawValue == null) return;
    final value = rawValue.trim();
    if (value.isEmpty) {
      // Emit an empty entry so that with preserveMetadata the old tag is
      // overridden (cleared) by FFmpeg's `-metadata key=""`.
      entries.add(MapEntry(key, ''));
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
          m4aMap['date'] = value;
          break;
        case 'YEAR':
          if (!m4aMap.containsKey('date') || m4aMap['date']!.isEmpty) {
            m4aMap['date'] = value;
          }
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
          id3Map['date'] = value;
          break;
        case 'YEAR':
          if (!id3Map.containsKey('date') || id3Map['date']!.isEmpty) {
            id3Map['date'] = value;
          }
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
        // ReplayGain as TXXX user-defined frames
        // FFmpeg writes these as TXXX frames automatically with uppercase keys
        case 'REPLAYGAINTRACKGAIN':
          id3Map['REPLAYGAIN_TRACK_GAIN'] = value;
          break;
        case 'REPLAYGAINTRACKPEAK':
          id3Map['REPLAYGAIN_TRACK_PEAK'] = value;
          break;
        case 'REPLAYGAINALBUMGAIN':
          id3Map['REPLAYGAIN_ALBUM_GAIN'] = value;
          break;
        case 'REPLAYGAINALBUMPEAK':
          id3Map['REPLAYGAIN_ALBUM_PEAK'] = value;
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
      final arguments = <String>[
        '-v',
        'error',
        '-hide_banner',
        '-i',
        audioPath,
      ];

      final startTime = _formatSecondsForFFmpeg(track.startSec);
      arguments
        ..add('-ss')
        ..add(startTime);

      if (track.endSec > 0) {
        final endTime = _formatSecondsForFFmpeg(track.endSec);
        arguments
          ..add('-to')
          ..add(endTime);
      }

      if (outputExt == 'flac') {
        arguments
          ..add('-c:a')
          ..add('flac')
          ..add('-compression_level')
          ..add('8');
      } else {
        arguments
          ..add('-c:a')
          ..add('copy');
      }

      final artist = track.artist.isNotEmpty
          ? track.artist
          : (albumMetadata['artist'] ?? '');
      final album = albumMetadata['album'] ?? '';
      final genre = albumMetadata['genre'] ?? '';
      final date = albumMetadata['date'] ?? '';
      final cueMetadata = <String, String>{};

      void addMeta(String key, String value) {
        if (value.isNotEmpty) {
          cueMetadata[key] = value;
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

      _appendMappedMetadataToArguments(arguments, cueMetadata);
      arguments
        ..add(outputPath)
        ..add('-y');

      _log.d('CUE split track ${track.number}');
      final result = await _executeWithArguments(arguments);
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

/// Result of an EBU R128 loudness scan, used to compute ReplayGain tags.
class ReplayGainResult {
  /// Track gain in dB, e.g. "-6.50 dB"
  final String trackGain;

  /// Track peak as a linear ratio, e.g. "0.988831"
  final String trackPeak;

  /// Raw integrated loudness in LUFS (needed for album gain computation)
  final double integratedLufs;

  /// Raw true peak as linear ratio (needed for album peak computation)
  final double truePeakLinear;

  const ReplayGainResult({
    required this.trackGain,
    required this.trackPeak,
    required this.integratedLufs,
    required this.truePeakLinear,
  });

  @override
  String toString() =>
      'ReplayGainResult(trackGain: $trackGain, trackPeak: $trackPeak)';
}
