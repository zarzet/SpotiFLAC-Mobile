// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webdav_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

WebDavConfig _$WebDavConfigFromJson(Map<String, dynamic> json) => WebDavConfig(
      enabled: json['enabled'] as bool? ?? false,
      serverUrl: json['serverUrl'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
      remotePath: json['remotePath'] as String? ?? '/SpotiFLAC',
      deleteLocalAfterUpload: json['deleteLocalAfterUpload'] as bool? ?? true,
      retryOnFailure: json['retryOnFailure'] as bool? ?? true,
      maxRetries: (json['maxRetries'] as num?)?.toInt() ?? 3,
    );

Map<String, dynamic> _$WebDavConfigToJson(WebDavConfig instance) =>
    <String, dynamic>{
      'enabled': instance.enabled,
      'serverUrl': instance.serverUrl,
      'username': instance.username,
      'password': instance.password,
      'remotePath': instance.remotePath,
      'deleteLocalAfterUpload': instance.deleteLocalAfterUpload,
      'retryOnFailure': instance.retryOnFailure,
      'maxRetries': instance.maxRetries,
    };

WebDavUploadItem _$WebDavUploadItemFromJson(Map<String, dynamic> json) =>
    WebDavUploadItem(
      id: json['id'] as String,
      localPath: json['localPath'] as String,
      remotePath: json['remotePath'] as String,
      trackName: json['trackName'] as String,
      artistName: json['artistName'] as String,
      albumName: json['albumName'] as String?,
      status: $enumDecodeNullable(_$WebDavUploadStatusEnumMap, json['status']) ??
          WebDavUploadStatus.pending,
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      error: json['error'] as String?,
      retryCount: (json['retryCount'] as num?)?.toInt() ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] == null
          ? null
          : DateTime.parse(json['completedAt'] as String),
    );

Map<String, dynamic> _$WebDavUploadItemToJson(WebDavUploadItem instance) =>
    <String, dynamic>{
      'id': instance.id,
      'localPath': instance.localPath,
      'remotePath': instance.remotePath,
      'trackName': instance.trackName,
      'artistName': instance.artistName,
      'albumName': instance.albumName,
      'status': _$WebDavUploadStatusEnumMap[instance.status]!,
      'progress': instance.progress,
      'error': instance.error,
      'retryCount': instance.retryCount,
      'createdAt': instance.createdAt.toIso8601String(),
      'completedAt': instance.completedAt?.toIso8601String(),
    };

const _$WebDavUploadStatusEnumMap = {
  WebDavUploadStatus.pending: 'pending',
  WebDavUploadStatus.uploading: 'uploading',
  WebDavUploadStatus.completed: 'completed',
  WebDavUploadStatus.failed: 'failed',
};
