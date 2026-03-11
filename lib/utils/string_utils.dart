String? normalizeOptionalString(String? value) {
  if (value == null) return null;
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;
  if (trimmed.toLowerCase() == 'null') return null;
  return trimmed;
}

String formatSampleRateKHz(int sampleRate) {
  final khz = sampleRate / 1000;
  final precision = sampleRate % 1000 == 0 ? 0 : 1;
  return '${khz.toStringAsFixed(precision)}kHz';
}

String? buildDisplayAudioQuality({
  int? bitDepth,
  int? sampleRate,
  int? bitrateKbps,
  String? format,
  String? storedQuality,
}) {
  if (bitrateKbps != null && bitrateKbps > 0) {
    final normalizedFormat = normalizeOptionalString(format)?.toUpperCase();
    return normalizedFormat != null
        ? '$normalizedFormat ${bitrateKbps}kbps'
        : '${bitrateKbps}kbps';
  }

  if (bitDepth != null &&
      bitDepth > 0 &&
      sampleRate != null &&
      sampleRate > 0) {
    return '$bitDepth-bit/${formatSampleRateKHz(sampleRate)}';
  }

  return normalizeOptionalString(storedQuality);
}

bool isPlaceholderQualityLabel(String? quality) {
  final normalized = normalizeOptionalString(quality)?.toLowerCase();
  if (normalized == null) return false;

  return const {
    'best',
    'lossless',
    'hi-res',
    'hi-res-max',
    'high',
    'cd',
  }.contains(normalized);
}
