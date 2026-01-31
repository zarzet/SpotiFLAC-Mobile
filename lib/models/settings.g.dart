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
  updateChannel: json['updateChannel'] as String? ?? 'stable',
  hasSearchedBefore: json['hasSearchedBefore'] as bool? ?? false,
  folderOrganization: json['folderOrganization'] as String? ?? 'none',
  historyViewMode: json['historyViewMode'] as String? ?? 'grid',
  historyFilterMode: json['historyFilterMode'] as String? ?? 'all',
  askQualityBeforeDownload: json['askQualityBeforeDownload'] as bool? ?? true,
  spotifyClientId: json['spotifyClientId'] as String? ?? '',
  spotifyClientSecret: json['spotifyClientSecret'] as String? ?? '',
  useCustomSpotifyCredentials:
      json['useCustomSpotifyCredentials'] as bool? ?? true,
  metadataSource: json['metadataSource'] as String? ?? 'deezer',
  enableLogging: json['enableLogging'] as bool? ?? false,
  useExtensionProviders: json['useExtensionProviders'] as bool? ?? true,
  searchProvider: json['searchProvider'] as String?,
  separateSingles: json['separateSingles'] as bool? ?? false,
  albumFolderStructure:
      json['albumFolderStructure'] as String? ?? 'artist_album',
  showExtensionStore: json['showExtensionStore'] as bool? ?? true,
  locale: json['locale'] as String? ?? 'system',
  enableLossyOption: json['enableLossyOption'] as bool? ?? false,
  lossyFormat: json['lossyFormat'] as String? ?? 'mp3',
  lossyBitrate: json['lossyBitrate'] as String? ?? 'mp3_320',
  lyricsMode: json['lyricsMode'] as String? ?? 'embed',
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
      'updateChannel': instance.updateChannel,
      'hasSearchedBefore': instance.hasSearchedBefore,
      'folderOrganization': instance.folderOrganization,
      'historyViewMode': instance.historyViewMode,
      'historyFilterMode': instance.historyFilterMode,
      'askQualityBeforeDownload': instance.askQualityBeforeDownload,
      'spotifyClientId': instance.spotifyClientId,
      'spotifyClientSecret': instance.spotifyClientSecret,
      'useCustomSpotifyCredentials': instance.useCustomSpotifyCredentials,
      'metadataSource': instance.metadataSource,
      'enableLogging': instance.enableLogging,
      'useExtensionProviders': instance.useExtensionProviders,
      'searchProvider': instance.searchProvider,
      'separateSingles': instance.separateSingles,
      'albumFolderStructure': instance.albumFolderStructure,
      'showExtensionStore': instance.showExtensionStore,
      'locale': instance.locale,
      'enableLossyOption': instance.enableLossyOption,
      'lossyFormat': instance.lossyFormat,
      'lossyBitrate': instance.lossyBitrate,
      'lyricsMode': instance.lyricsMode,
    };
