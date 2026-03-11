import 'dart:io';

const _androidStoragePathAliases = <String>[
  '/storage/emulated/0',
  '/storage/emulated/legacy',
  '/storage/self/primary',
  '/sdcard',
  '/mnt/sdcard',
];

Set<String> buildPathMatchKeys(String? filePath) {
  final raw = filePath?.trim() ?? '';
  if (raw.isEmpty) return const {};

  final cleaned = raw.startsWith('EXISTS:') ? raw.substring(7).trim() : raw;
  if (cleaned.isEmpty) return const {};

  final keys = <String>{};
  final visited = <String>{};

  void addNormalized(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return;
    if (!visited.add(trimmed)) return;

    keys.add(trimmed);
    keys.add(trimmed.toLowerCase());

    if (trimmed.contains('\\')) {
      final slash = trimmed.replaceAll('\\', '/');
      if (slash != trimmed) {
        addNormalized(slash);
      }
    }

    if (trimmed.contains('%')) {
      try {
        final decoded = Uri.decodeFull(trimmed);
        if (decoded != trimmed) {
          addNormalized(decoded);
        }
      } catch (_) {}
    }

    Uri? parsed;
    try {
      parsed = Uri.parse(trimmed);
    } catch (_) {}

    if (parsed != null && parsed.hasScheme) {
      final withoutQueryOrFragment = parsed.replace(
        query: null,
        fragment: null,
      );
      final uriString = withoutQueryOrFragment.toString();
      keys.add(uriString);
      keys.add(uriString.toLowerCase());

      if (parsed.scheme == 'file') {
        try {
          addNormalized(parsed.toFilePath());
        } catch (_) {}
      }
    } else if (trimmed.startsWith('/')) {
      try {
        final asFileUri = Uri.file(trimmed).toString();
        keys.add(asFileUri);
        keys.add(asFileUri.toLowerCase());
      } catch (_) {}
    }

    if (Platform.isAndroid) {
      for (final alias in _androidEquivalentPaths(trimmed)) {
        if (alias != trimmed) {
          addNormalized(alias);
        }
      }
    }
  }

  addNormalized(cleaned);
  return keys;
}

Iterable<String> _androidEquivalentPaths(String path) {
  final normalized = path.replaceAll('\\', '/');
  final lower = normalized.toLowerCase();
  String? suffix;

  for (final prefix in _androidStoragePathAliases) {
    if (lower == prefix) {
      suffix = '';
      break;
    }
    final withSlash = '$prefix/';
    if (lower.startsWith(withSlash)) {
      suffix = normalized.substring(prefix.length);
      break;
    }
  }

  if (suffix == null) return const [];
  return _androidStoragePathAliases.map((prefix) => '$prefix$suffix');
}
