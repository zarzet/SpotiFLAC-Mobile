// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

AppSettings _$AppSettingsFromJson(Map<String, dynamic> json) => AppSettings(
  defaultService: json['defaultService'] as String? ?? 'tidal',
  audioQuality: json['audioQuality'] as String? ?? 'LOSSLESS',
  filenameFormat: json['filenameFormat'] as String? ?? '{title} - {artist}',
  downloadDirectory: json['downloadDirectory'] as String? ?? '',
  autoFallback: json['autoFallback'] as bool? ?? true,
  embedLyrics: json['embedLyrics'] as bool? ?? true,
  maxQualityCover: json['maxQualityCover'] as bool? ?? true,
  isFirstLaunch: json['isFirstLaunch'] as bool? ?? true,
  concurrentDownloads: (json['concurrentDownloads'] as num?)?.toInt() ?? 1,
  checkForUpdates: json['checkForUpdates'] as bool? ?? true,
  hasSearchedBefore: json['hasSearchedBefore'] as bool? ?? false,
  folderOrganization: json['folderOrganization'] as String? ?? 'none',
  convertLyricsToRomaji: json['convertLyricsToRomaji'] as bool? ?? false,
  historyViewMode: json['historyViewMode'] as String? ?? 'list',
);

Map<String, dynamic> _$AppSettingsToJson(AppSettings instance) =>
    <String, dynamic>{
      'defaultService': instance.defaultService,
      'audioQuality': instance.audioQuality,
      'filenameFormat': instance.filenameFormat,
      'downloadDirectory': instance.downloadDirectory,
      'autoFallback': instance.autoFallback,
      'embedLyrics': instance.embedLyrics,
      'maxQualityCover': instance.maxQualityCover,
      'isFirstLaunch': instance.isFirstLaunch,
      'concurrentDownloads': instance.concurrentDownloads,
      'checkForUpdates': instance.checkForUpdates,
      'hasSearchedBefore': instance.hasSearchedBefore,
      'folderOrganization': instance.folderOrganization,
      'convertLyricsToRomaji': instance.convertLyricsToRomaji,
      'historyViewMode': instance.historyViewMode,
    };
