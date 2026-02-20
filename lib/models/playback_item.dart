import 'package:spotiflac_android/models/track.dart';

class PlaybackItem {
  final String id;
  final String title;
  final String artist;
  final String album;
  final String coverUrl;
  final String sourceUri;
  final bool isLocal;
  final String service;
  final int durationMs;

  // Stream quality metadata
  final String format;
  final int bitDepth;
  final int sampleRate;
  final int bitrate;

  // Original track reference for queue operations
  final Track? track;

  const PlaybackItem({
    required this.id,
    required this.title,
    required this.artist,
    this.album = '',
    this.coverUrl = '',
    required this.sourceUri,
    this.isLocal = false,
    this.service = '',
    this.durationMs = 0,
    this.format = '',
    this.bitDepth = 0,
    this.sampleRate = 0,
    this.bitrate = 0,
    this.track,
  });

  PlaybackItem copyWith({
    String? sourceUri,
    String? service,
    String? format,
    int? bitDepth,
    int? sampleRate,
    int? bitrate,
  }) {
    return PlaybackItem(
      id: id,
      title: title,
      artist: artist,
      album: album,
      coverUrl: coverUrl,
      sourceUri: sourceUri ?? this.sourceUri,
      isLocal: isLocal,
      service: service ?? this.service,
      durationMs: durationMs,
      format: format ?? this.format,
      bitDepth: bitDepth ?? this.bitDepth,
      sampleRate: sampleRate ?? this.sampleRate,
      bitrate: bitrate ?? this.bitrate,
      track: track,
    );
  }

  /// Human-readable quality label for UI display
  String get qualityLabel {
    final parts = <String>[];

    if (format.isNotEmpty) {
      parts.add(format.toUpperCase());
    }

    if (bitDepth > 0 && sampleRate > 0) {
      final srKhz = sampleRate >= 1000
          ? '${(sampleRate / 1000).toStringAsFixed(sampleRate % 1000 == 0 ? 0 : 1)}kHz'
          : '${sampleRate}Hz';
      parts.add('$bitDepth-bit / $srKhz');
    } else if (bitrate > 0) {
      parts.add('${bitrate}kbps');
    }

    return parts.join(' ');
  }

  /// Whether this item has cover art that is a local file path
  bool get hasLocalCover {
    if (coverUrl.isEmpty) return false;
    return !coverUrl.startsWith('http://') && !coverUrl.startsWith('https://');
  }
}
