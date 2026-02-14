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
  storageMode: json['storageMode'] as String? ?? 'app',
  downloadTreeUri: json['downloadTreeUri'] as String? ?? '',
  autoFallback: json['autoFallback'] as bool? ?? true,
  embedLyrics: json['embedLyrics'] as bool? ?? true,
  maxQualityCover: json['maxQualityCover'] as bool? ?? true,
  isFirstLaunch: json['isFirstLaunch'] as bool? ?? true,
  concurrentDownloads: (json['concurrentDownloads'] as num?)?.toInt() ?? 1,
  checkForUpdates: json['checkForUpdates'] as bool? ?? true,
  updateChannel: json['updateChannel'] as String? ?? 'stable',
  hasSearchedBefore: json['hasSearchedBefore'] as bool? ?? false,
  folderOrganization: json['folderOrganization'] as String? ?? 'none',
  useAlbumArtistForFolders: json['useAlbumArtistForFolders'] as bool? ?? true,
  usePrimaryArtistOnly: json['usePrimaryArtistOnly'] as bool? ?? false,
  filterContributingArtistsInAlbumArtist:
      json['filterContributingArtistsInAlbumArtist'] as bool? ?? false,
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
  lyricsMode: json['lyricsMode'] as String? ?? 'embed',
  tidalHighFormat: json['tidalHighFormat'] as String? ?? 'mp3_320',
  useAllFilesAccess: json['useAllFilesAccess'] as bool? ?? false,
  autoExportFailedDownloads:
      json['autoExportFailedDownloads'] as bool? ?? false,
  downloadNetworkMode: json['downloadNetworkMode'] as String? ?? 'any',
  localLibraryEnabled: json['localLibraryEnabled'] as bool? ?? false,
  localLibraryPath: json['localLibraryPath'] as String? ?? '',
  localLibraryShowDuplicates:
      json['localLibraryShowDuplicates'] as bool? ?? true,
  hasCompletedTutorial: json['hasCompletedTutorial'] as bool? ?? false,
  lyricsProviders:
      (json['lyricsProviders'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const ['lrclib', 'musixmatch', 'netease', 'apple_music', 'qqmusic'],
  lyricsIncludeTranslationNetease:
      json['lyricsIncludeTranslationNetease'] as bool? ?? false,
  lyricsIncludeRomanizationNetease:
      json['lyricsIncludeRomanizationNetease'] as bool? ?? false,
  lyricsMultiPersonWordByWord:
      json['lyricsMultiPersonWordByWord'] as bool? ?? true,
  musixmatchLanguage: json['musixmatchLanguage'] as String? ?? '',
);

Map<String, dynamic> _$AppSettingsToJson(
  AppSettings instance,
) => <String, dynamic>{
  'defaultService': instance.defaultService,
  'audioQuality': instance.audioQuality,
  'filenameFormat': instance.filenameFormat,
  'downloadDirectory': instance.downloadDirectory,
  'storageMode': instance.storageMode,
  'downloadTreeUri': instance.downloadTreeUri,
  'autoFallback': instance.autoFallback,
  'embedLyrics': instance.embedLyrics,
  'maxQualityCover': instance.maxQualityCover,
  'isFirstLaunch': instance.isFirstLaunch,
  'concurrentDownloads': instance.concurrentDownloads,
  'checkForUpdates': instance.checkForUpdates,
  'updateChannel': instance.updateChannel,
  'hasSearchedBefore': instance.hasSearchedBefore,
  'folderOrganization': instance.folderOrganization,
  'useAlbumArtistForFolders': instance.useAlbumArtistForFolders,
  'usePrimaryArtistOnly': instance.usePrimaryArtistOnly,
  'filterContributingArtistsInAlbumArtist':
      instance.filterContributingArtistsInAlbumArtist,
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
  'lyricsMode': instance.lyricsMode,
  'tidalHighFormat': instance.tidalHighFormat,
  'useAllFilesAccess': instance.useAllFilesAccess,
  'autoExportFailedDownloads': instance.autoExportFailedDownloads,
  'downloadNetworkMode': instance.downloadNetworkMode,
  'localLibraryEnabled': instance.localLibraryEnabled,
  'localLibraryPath': instance.localLibraryPath,
  'localLibraryShowDuplicates': instance.localLibraryShowDuplicates,
  'hasCompletedTutorial': instance.hasCompletedTutorial,
  'lyricsProviders': instance.lyricsProviders,
  'lyricsIncludeTranslationNetease': instance.lyricsIncludeTranslationNetease,
  'lyricsIncludeRomanizationNetease': instance.lyricsIncludeRomanizationNetease,
  'lyricsMultiPersonWordByWord': instance.lyricsMultiPersonWordByWord,
  'musixmatchLanguage': instance.musixmatchLanguage,
};
