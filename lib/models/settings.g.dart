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
  embedMetadata: json['embedMetadata'] as bool? ?? true,
  artistTagMode: json['artistTagMode'] as String? ?? artistTagModeJoined,
  embedLyrics: json['embedLyrics'] as bool? ?? true,
  embedReplayGain: json['embedReplayGain'] as bool? ?? false,
  maxQualityCover: json['maxQualityCover'] as bool? ?? true,
  isFirstLaunch: json['isFirstLaunch'] as bool? ?? true,
  concurrentDownloads: (json['concurrentDownloads'] as num?)?.toInt() ?? 1,
  checkForUpdates: json['checkForUpdates'] as bool? ?? true,
  updateChannel: json['updateChannel'] as String? ?? 'stable',
  hasSearchedBefore: json['hasSearchedBefore'] as bool? ?? false,
  folderOrganization: json['folderOrganization'] as String? ?? 'none',
  createPlaylistFolder: json['createPlaylistFolder'] as bool? ?? false,
  useAlbumArtistForFolders: json['useAlbumArtistForFolders'] as bool? ?? true,
  usePrimaryArtistOnly: json['usePrimaryArtistOnly'] as bool? ?? false,
  filterContributingArtistsInAlbumArtist:
      json['filterContributingArtistsInAlbumArtist'] as bool? ?? false,
  historyViewMode: json['historyViewMode'] as String? ?? 'grid',
  historyFilterMode: json['historyFilterMode'] as String? ?? 'all',
  askQualityBeforeDownload: json['askQualityBeforeDownload'] as bool? ?? true,
  enableLogging: json['enableLogging'] as bool? ?? false,
  useExtensionProviders: json['useExtensionProviders'] as bool? ?? true,
  downloadFallbackExtensionIds:
      (json['downloadFallbackExtensionIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
  searchProvider: json['searchProvider'] as String?,
  defaultSearchTab: json['defaultSearchTab'] as String? ?? 'all',
  homeFeedProvider: json['homeFeedProvider'] as String?,
  separateSingles: json['separateSingles'] as bool? ?? false,
  singleFilenameFormat:
      json['singleFilenameFormat'] as String? ?? '{title} - {artist}',
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
  networkCompatibilityMode: json['networkCompatibilityMode'] as bool? ?? false,
  songLinkRegion: json['songLinkRegion'] as String? ?? 'US',
  localLibraryEnabled: json['localLibraryEnabled'] as bool? ?? false,
  localLibraryPath: json['localLibraryPath'] as String? ?? '',
  localLibraryBookmark: json['localLibraryBookmark'] as String? ?? '',
  localLibraryShowDuplicates:
      json['localLibraryShowDuplicates'] as bool? ?? true,
  localLibraryAutoScan: json['localLibraryAutoScan'] as String? ?? 'off',
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
      json['lyricsMultiPersonWordByWord'] as bool? ?? false,
  musixmatchLanguage: json['musixmatchLanguage'] as String? ?? '',
  lastSeenVersion: json['lastSeenVersion'] as String? ?? '',
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
  'embedMetadata': instance.embedMetadata,
  'artistTagMode': instance.artistTagMode,
  'embedLyrics': instance.embedLyrics,
  'embedReplayGain': instance.embedReplayGain,
  'maxQualityCover': instance.maxQualityCover,
  'isFirstLaunch': instance.isFirstLaunch,
  'concurrentDownloads': instance.concurrentDownloads,
  'checkForUpdates': instance.checkForUpdates,
  'updateChannel': instance.updateChannel,
  'hasSearchedBefore': instance.hasSearchedBefore,
  'folderOrganization': instance.folderOrganization,
  'createPlaylistFolder': instance.createPlaylistFolder,
  'useAlbumArtistForFolders': instance.useAlbumArtistForFolders,
  'usePrimaryArtistOnly': instance.usePrimaryArtistOnly,
  'filterContributingArtistsInAlbumArtist':
      instance.filterContributingArtistsInAlbumArtist,
  'historyViewMode': instance.historyViewMode,
  'historyFilterMode': instance.historyFilterMode,
  'askQualityBeforeDownload': instance.askQualityBeforeDownload,
  'enableLogging': instance.enableLogging,
  'useExtensionProviders': instance.useExtensionProviders,
  'downloadFallbackExtensionIds': instance.downloadFallbackExtensionIds,
  'searchProvider': instance.searchProvider,
  'defaultSearchTab': instance.defaultSearchTab,
  'homeFeedProvider': instance.homeFeedProvider,
  'separateSingles': instance.separateSingles,
  'singleFilenameFormat': instance.singleFilenameFormat,
  'albumFolderStructure': instance.albumFolderStructure,
  'showExtensionStore': instance.showExtensionStore,
  'locale': instance.locale,
  'lyricsMode': instance.lyricsMode,
  'tidalHighFormat': instance.tidalHighFormat,
  'useAllFilesAccess': instance.useAllFilesAccess,
  'autoExportFailedDownloads': instance.autoExportFailedDownloads,
  'downloadNetworkMode': instance.downloadNetworkMode,
  'networkCompatibilityMode': instance.networkCompatibilityMode,
  'songLinkRegion': instance.songLinkRegion,
  'localLibraryEnabled': instance.localLibraryEnabled,
  'localLibraryPath': instance.localLibraryPath,
  'localLibraryBookmark': instance.localLibraryBookmark,
  'localLibraryShowDuplicates': instance.localLibraryShowDuplicates,
  'localLibraryAutoScan': instance.localLibraryAutoScan,
  'hasCompletedTutorial': instance.hasCompletedTutorial,
  'lyricsProviders': instance.lyricsProviders,
  'lyricsIncludeTranslationNetease': instance.lyricsIncludeTranslationNetease,
  'lyricsIncludeRomanizationNetease': instance.lyricsIncludeRomanizationNetease,
  'lyricsMultiPersonWordByWord': instance.lyricsMultiPersonWordByWord,
  'musixmatchLanguage': instance.musixmatchLanguage,
  'lastSeenVersion': instance.lastSeenVersion,
};
