import 'package:json_annotation/json_annotation.dart';
import 'package:spotiflac_android/models/track.dart';

part 'download_item.g.dart';

enum DownloadStatus {
  queued,
  downloading,
  finalizing,
  completed,
  failed,
  skipped,
}

enum DownloadErrorType {
  unknown,
  notFound,
  rateLimit,
  network,
  permission,
}

@JsonSerializable()
class DownloadItem {
  final String id;
  final Track track;
  final String service;
  final DownloadStatus status;
  final double progress;
  final double speedMBps;
  final int bytesReceived; // Bytes downloaded so far (for unknown size downloads)
  final String? filePath;
  final String? error;
  final DownloadErrorType? errorType;
  final DateTime createdAt;
  final String? qualityOverride; // Override quality for this specific download
  final String? playlistName; // Playlist context for folder organization

  const DownloadItem({
    required this.id,
    required this.track,
    required this.service,
    this.status = DownloadStatus.queued,
    this.progress = 0.0,
    this.speedMBps = 0.0,
    this.bytesReceived = 0,
    this.filePath,
    this.error,
    this.errorType,
    required this.createdAt,
    this.qualityOverride,
    this.playlistName,
  });

  DownloadItem copyWith({
    String? id,
    Track? track,
    String? service,
    DownloadStatus? status,
    double? progress,
    double? speedMBps,
    int? bytesReceived,
    String? filePath,
    String? error,
    DownloadErrorType? errorType,
    DateTime? createdAt,
    String? qualityOverride,
    String? playlistName,
  }) {
    return DownloadItem(
      id: id ?? this.id,
      track: track ?? this.track,
      service: service ?? this.service,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      speedMBps: speedMBps ?? this.speedMBps,
      bytesReceived: bytesReceived ?? this.bytesReceived,
      filePath: filePath ?? this.filePath,
      error: error ?? this.error,
      errorType: errorType ?? this.errorType,
      createdAt: createdAt ?? this.createdAt,
      qualityOverride: qualityOverride ?? this.qualityOverride,
      playlistName: playlistName ?? this.playlistName,
    );
  }

  String get errorMessage {
    if (error == null) return '';
    
    switch (errorType) {
      case DownloadErrorType.notFound:
        return 'Song not found on any service';
      case DownloadErrorType.rateLimit:
        return 'Rate limit reached, try again later';
      case DownloadErrorType.network:
        return 'Connection failed, check your internet';
      case DownloadErrorType.permission:
        return 'Cannot write to folder, check storage permission';
      default:
        return error ?? 'An error occurred';
    }
  }

  factory DownloadItem.fromJson(Map<String, dynamic> json) =>
      _$DownloadItemFromJson(json);
  Map<String, dynamic> toJson() => _$DownloadItemToJson(this);
}
