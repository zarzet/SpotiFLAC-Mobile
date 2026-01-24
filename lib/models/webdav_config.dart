import 'package:json_annotation/json_annotation.dart';

part 'webdav_config.g.dart';

@JsonSerializable()
class WebDavConfig {
  final bool enabled;
  final String serverUrl;
  final String username;
  final String password;
  final String remotePath;
  final bool deleteLocalAfterUpload;
  final bool retryOnFailure;
  final int maxRetries;

  const WebDavConfig({
    this.enabled = false,
    this.serverUrl = '',
    this.username = '',
    this.password = '',
    this.remotePath = '/SpotiFLAC',
    this.deleteLocalAfterUpload = true,
    this.retryOnFailure = true,
    this.maxRetries = 3,
  });

  bool get isConfigured =>
      serverUrl.isNotEmpty && username.isNotEmpty && password.isNotEmpty;

  WebDavConfig copyWith({
    bool? enabled,
    String? serverUrl,
    String? username,
    String? password,
    String? remotePath,
    bool? deleteLocalAfterUpload,
    bool? retryOnFailure,
    int? maxRetries,
  }) {
    return WebDavConfig(
      enabled: enabled ?? this.enabled,
      serverUrl: serverUrl ?? this.serverUrl,
      username: username ?? this.username,
      password: password ?? this.password,
      remotePath: remotePath ?? this.remotePath,
      deleteLocalAfterUpload:
          deleteLocalAfterUpload ?? this.deleteLocalAfterUpload,
      retryOnFailure: retryOnFailure ?? this.retryOnFailure,
      maxRetries: maxRetries ?? this.maxRetries,
    );
  }

  factory WebDavConfig.fromJson(Map<String, dynamic> json) =>
      _$WebDavConfigFromJson(json);
  Map<String, dynamic> toJson() => _$WebDavConfigToJson(this);
}

enum WebDavUploadStatus { pending, uploading, completed, failed }

@JsonSerializable()
class WebDavUploadItem {
  final String id;
  final String localPath;
  final String remotePath;
  final String trackName;
  final String artistName;
  final String? albumName;
  final WebDavUploadStatus status;
  final double progress;
  final String? error;
  final int retryCount;
  final DateTime createdAt;
  final DateTime? completedAt;

  const WebDavUploadItem({
    required this.id,
    required this.localPath,
    required this.remotePath,
    required this.trackName,
    required this.artistName,
    this.albumName,
    this.status = WebDavUploadStatus.pending,
    this.progress = 0.0,
    this.error,
    this.retryCount = 0,
    required this.createdAt,
    this.completedAt,
  });

  WebDavUploadItem copyWith({
    String? id,
    String? localPath,
    String? remotePath,
    String? trackName,
    String? artistName,
    String? albumName,
    WebDavUploadStatus? status,
    double? progress,
    String? error,
    bool clearError = false,
    int? retryCount,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return WebDavUploadItem(
      id: id ?? this.id,
      localPath: localPath ?? this.localPath,
      remotePath: remotePath ?? this.remotePath,
      trackName: trackName ?? this.trackName,
      artistName: artistName ?? this.artistName,
      albumName: albumName ?? this.albumName,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      error: clearError ? null : (error ?? this.error),
      retryCount: retryCount ?? this.retryCount,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory WebDavUploadItem.fromJson(Map<String, dynamic> json) =>
      _$WebDavUploadItemFromJson(json);
  Map<String, dynamic> toJson() => _$WebDavUploadItemToJson(this);
}
