import 'dart:io';

import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spotiflac_android/services/platform_bridge.dart';
import 'package:spotiflac_android/utils/mime_utils.dart';

/// Regular expression to detect iOS app container paths.
/// Matches paths like /var/mobile/Containers/Data/Application/{UUID}
/// or /private/var/mobile/Containers/Data/Application/{UUID}
final _iosContainerRootPattern = RegExp(
  r'^(/private)?/var/mobile/Containers/Data/Application/[A-F0-9\-]+/?$',
  caseSensitive: false,
);
final _iosContainerPathWithoutLeadingSlashPattern = RegExp(
  r'^(private/)?var/mobile/Containers/Data/Application/[A-F0-9\-]+/.+',
  caseSensitive: false,
);
final _iosLegacyRelativeDocumentsPattern = RegExp(
  r'^Data/Application/[A-F0-9\-]+/Documents(?:/(.*))?$',
  caseSensitive: false,
);

/// Checks if a path is a valid writable directory on iOS.
/// Returns false if:
/// - The path is the app container root (not writable)
/// - The path is an iCloud Drive path (not accessible by Go backend)
/// - The path is outside the app sandbox
bool isValidIosWritablePath(String path) {
  if (!Platform.isIOS) return true;
  if (path.isEmpty) return false;
  if (!path.startsWith('/')) return false;

  // Check if it's the container root (without Documents/, tmp/, etc.)
  if (_iosContainerRootPattern.hasMatch(path)) {
    return false;
  }

  // Check for iCloud Drive paths
  if (path.contains('Mobile Documents') ||
      path.contains('CloudDocs') ||
      path.contains('com~apple~CloudDocs')) {
    return false;
  }

  // Ensure path contains a valid subdirectory (Documents, tmp, Library, etc.)
  // This handles cases where FilePicker returns container root
  final containerPattern = RegExp(
    r'/var/mobile/Containers/Data/Application/[A-F0-9\-]+',
    caseSensitive: false,
  );
  final match = containerPattern.firstMatch(path);
  if (match != null) {
    final remainingPath = path.substring(match.end);
    // Valid paths should have something after the UUID
    if (remainingPath.isEmpty || remainingPath == '/') {
      return false;
    }
  }

  return true;
}

/// Validates and potentially corrects an iOS path.
/// Returns a valid Documents subdirectory path if the input is invalid.
Future<String> validateOrFixIosPath(
  String path, {
  String subfolder = 'SpotiFLAC',
}) async {
  if (!Platform.isIOS) return path;

  final trimmed = path.trim();
  if (isValidIosWritablePath(trimmed)) {
    return trimmed;
  }

  final docDir = await getApplicationDocumentsDirectory();
  final candidates = <String>[];

  if (trimmed.isNotEmpty) {
    candidates.add(trimmed);
  }

  // Some pickers can return absolute iOS paths without the leading slash.
  if (_iosContainerPathWithoutLeadingSlashPattern.hasMatch(trimmed)) {
    candidates.add('/$trimmed');
  }

  // Recover legacy relative iOS path format:
  // Data/Application/<UUID>/Documents/<subdir>
  final legacyRelativeMatch = _iosLegacyRelativeDocumentsPattern.firstMatch(
    trimmed,
  );
  if (legacyRelativeMatch != null) {
    final suffix = (legacyRelativeMatch.group(1) ?? '').trim();
    final normalizedSuffix = suffix.startsWith('/')
        ? suffix.substring(1)
        : suffix;
    candidates.add(
      normalizedSuffix.isEmpty
          ? docDir.path
          : '${docDir.path}/$normalizedSuffix',
    );
  }

  // Generic salvage for relative paths containing `Documents/...`.
  if (!trimmed.startsWith('/')) {
    final documentsMarker = 'Documents/';
    final index = trimmed.indexOf(documentsMarker);
    if (index >= 0) {
      final suffix = trimmed.substring(index + documentsMarker.length).trim();
      candidates.add(suffix.isEmpty ? docDir.path : '${docDir.path}/$suffix');
    }
  }

  for (final candidate in candidates) {
    if (isValidIosWritablePath(candidate)) {
      return candidate;
    }
  }

  // Fall back to app Documents directory
  final musicDir = Directory('${docDir.path}/$subfolder');
  if (!await musicDir.exists()) {
    await musicDir.create(recursive: true);
  }
  return musicDir.path;
}

/// Detailed result for iOS path validation
class IosPathValidationResult {
  final bool isValid;
  final String? correctedPath;
  final String? errorReason;

  const IosPathValidationResult({
    required this.isValid,
    this.correctedPath,
    this.errorReason,
  });
}

/// Validates an iOS path and returns detailed information about the result.
IosPathValidationResult validateIosPath(String path) {
  if (!Platform.isIOS) {
    return const IosPathValidationResult(isValid: true);
  }

  if (path.isEmpty) {
    return const IosPathValidationResult(
      isValid: false,
      errorReason: 'Path is empty',
    );
  }

  if (!path.startsWith('/')) {
    return const IosPathValidationResult(
      isValid: false,
      errorReason:
          'Invalid path format. Please choose a local folder from Files.',
    );
  }

  // Check if it's the container root
  if (_iosContainerRootPattern.hasMatch(path)) {
    return const IosPathValidationResult(
      isValid: false,
      errorReason:
          'Cannot write to app container root. Please choose a subfolder like Documents.',
    );
  }

  // Check for iCloud Drive paths
  if (path.contains('Mobile Documents') ||
      path.contains('CloudDocs') ||
      path.contains('com~apple~CloudDocs')) {
    return const IosPathValidationResult(
      isValid: false,
      errorReason:
          'iCloud Drive is not supported. Please choose a local folder.',
    );
  }

  // Check for container root without subdirectory
  final containerPattern = RegExp(
    r'/var/mobile/Containers/Data/Application/[A-F0-9\-]+',
    caseSensitive: false,
  );
  final match = containerPattern.firstMatch(path);
  if (match != null) {
    final remainingPath = path.substring(match.end);
    if (remainingPath.isEmpty || remainingPath == '/') {
      return const IosPathValidationResult(
        isValid: false,
        errorReason:
            'Cannot write to app container root. Please use the default folder or choose a different location.',
      );
    }
  }

  return const IosPathValidationResult(isValid: true);
}

class FileAccessStat {
  final int? size;
  final DateTime? modified;

  const FileAccessStat({this.size, this.modified});
}

bool isContentUri(String? path) {
  return path != null && path.startsWith('content://');
}

Future<bool> fileExists(String? path) async {
  if (path == null || path.isEmpty) return false;
  if (isContentUri(path)) {
    return PlatformBridge.safExists(path);
  }
  return File(path).exists();
}

Future<void> deleteFile(String? path) async {
  if (path == null || path.isEmpty) return;
  if (isContentUri(path)) {
    await PlatformBridge.safDelete(path);
    return;
  }
  try {
    await File(path).delete();
  } catch (_) {}
}

Future<FileAccessStat?> fileStat(String? path) async {
  if (path == null || path.isEmpty) return null;
  if (isContentUri(path)) {
    final stat = await PlatformBridge.safStat(path);
    final exists = stat['exists'] as bool? ?? true;
    if (!exists) return null;
    return FileAccessStat(
      size: stat['size'] as int?,
      modified: stat['modified'] != null
          ? DateTime.fromMillisecondsSinceEpoch(stat['modified'] as int)
          : null,
    );
  }

  final stat = await FileStat.stat(path);
  if (stat.type == FileSystemEntityType.notFound) return null;
  return FileAccessStat(size: stat.size, modified: stat.modified);
}

Future<void> openFile(String path) async {
  if (isContentUri(path)) {
    await PlatformBridge.openContentUri(path, mimeType: '');
    return;
  }
  final mimeType = audioMimeTypeForPath(path);
  final result = await OpenFilex.open(path, type: mimeType);
  if (result.type != ResultType.done) {
    throw Exception(result.message);
  }
}
