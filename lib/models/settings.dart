import 'package:json_annotation/json_annotation.dart';

part 'settings.g.dart';

@JsonSerializable()
class AppSettings {
  final String defaultService;
  final String audioQuality;
  final String filenameFormat;
  final String downloadDirectory;
  final String storageMode; // 'app' or 'saf'
  final String downloadTreeUri; // SAF persistable tree URI
  final bool autoFallback;
  final bool embedLyrics;
  final bool maxQualityCover;
  final bool isFirstLaunch;
  final int concurrentDownloads;
  final bool checkForUpdates;
  final String updateChannel;
  final bool hasSearchedBefore;
  final String folderOrganization;
  final bool useAlbumArtistForFolders;
  final bool usePrimaryArtistOnly; // Strip featured artists from folder name
  final bool filterContributingArtistsInAlbumArtist;
  final String historyViewMode;
  final String historyFilterMode;
  final bool askQualityBeforeDownload;
  final String spotifyClientId;
  final String spotifyClientSecret;
  final bool useCustomSpotifyCredentials;
  final String metadataSource;
  final bool enableLogging;
  final bool useExtensionProviders;
  final String? searchProvider;
  final bool separateSingles;
  final String albumFolderStructure;
  final bool showExtensionStore;
  final String locale;
  final String lyricsMode;
  final String
  tidalHighFormat; // Format for Tidal HIGH quality: 'mp3_320', 'opus_256', or 'opus_128'
  final bool
  useAllFilesAccess; // Android 13+ only: enable MANAGE_EXTERNAL_STORAGE
  final bool
  autoExportFailedDownloads; // Auto export failed downloads to TXT file
  final String
  downloadNetworkMode; // 'any' = WiFi + Mobile, 'wifi_only' = WiFi only

  // Local Library Settings
  final bool localLibraryEnabled; // Enable local library scanning
  final String localLibraryPath; // Path to scan for audio files
  final bool
  localLibraryShowDuplicates; // Show indicator when searching for existing tracks

  // Tutorial/Onboarding
  final bool
  hasCompletedTutorial; // Track if user has completed the app tutorial

  // Lyrics Provider Settings
  final List<String>
  lyricsProviders; // Ordered list of enabled lyrics provider IDs
  final bool
  lyricsIncludeTranslationNetease; // Append translated lyrics (Netease)
  final bool
  lyricsIncludeRomanizationNetease; // Append romanized lyrics (Netease)
  final bool
  lyricsMultiPersonWordByWord; // Enable v1/v2 + [bg:] tags for Apple/QQ syllable lyrics
  final String
  musixmatchLanguage; // Optional ISO language code for Musixmatch localized lyrics

  const AppSettings({
    this.defaultService = 'tidal',
    this.audioQuality = 'LOSSLESS',
    this.filenameFormat = '{title} - {artist}',
    this.downloadDirectory = '',
    this.storageMode = 'app',
    this.downloadTreeUri = '',
    this.autoFallback = true,
    this.embedLyrics = true,
    this.maxQualityCover = true,
    this.isFirstLaunch = true,
    this.concurrentDownloads = 1,
    this.checkForUpdates = true,
    this.updateChannel = 'stable',
    this.hasSearchedBefore = false,
    this.folderOrganization = 'none',
    this.useAlbumArtistForFolders = true,
    this.usePrimaryArtistOnly = false,
    this.filterContributingArtistsInAlbumArtist = false,
    this.historyViewMode = 'grid',
    this.historyFilterMode = 'all',
    this.askQualityBeforeDownload = true,
    this.spotifyClientId = '',
    this.spotifyClientSecret = '',
    this.useCustomSpotifyCredentials = true,
    this.metadataSource = 'deezer',
    this.enableLogging = false,
    this.useExtensionProviders = true,
    this.searchProvider,
    this.separateSingles = false,
    this.albumFolderStructure = 'artist_album',
    this.showExtensionStore = true,
    this.locale = 'system',
    this.lyricsMode = 'embed',
    this.tidalHighFormat = 'mp3_320',
    this.useAllFilesAccess = false,
    this.autoExportFailedDownloads = false,
    this.downloadNetworkMode = 'any',
    // Local Library defaults
    this.localLibraryEnabled = false,
    this.localLibraryPath = '',
    this.localLibraryShowDuplicates = true,
    // Tutorial default
    this.hasCompletedTutorial = false,
    // Lyrics providers default order
    this.lyricsProviders = const ['lrclib', 'musixmatch', 'netease', 'apple_music', 'qqmusic'],
    this.lyricsIncludeTranslationNetease = false,
    this.lyricsIncludeRomanizationNetease = false,
    this.lyricsMultiPersonWordByWord = true,
    this.musixmatchLanguage = '',
  });

  AppSettings copyWith({
    String? defaultService,
    String? audioQuality,
    String? filenameFormat,
    String? downloadDirectory,
    String? storageMode,
    String? downloadTreeUri,
    bool? autoFallback,
    bool? embedLyrics,
    bool? maxQualityCover,
    bool? isFirstLaunch,
    int? concurrentDownloads,
    bool? checkForUpdates,
    String? updateChannel,
    bool? hasSearchedBefore,
    String? folderOrganization,
    bool? useAlbumArtistForFolders,
    bool? usePrimaryArtistOnly,
    bool? filterContributingArtistsInAlbumArtist,
    String? historyViewMode,
    String? historyFilterMode,
    bool? askQualityBeforeDownload,
    String? spotifyClientId,
    String? spotifyClientSecret,
    bool? useCustomSpotifyCredentials,
    String? metadataSource,
    bool? enableLogging,
    bool? useExtensionProviders,
    String? searchProvider,
    bool clearSearchProvider = false,
    bool? separateSingles,
    String? albumFolderStructure,
    bool? showExtensionStore,
    String? locale,
    String? lyricsMode,
    String? tidalHighFormat,
    bool? useAllFilesAccess,
    bool? autoExportFailedDownloads,
    String? downloadNetworkMode,
    // Local Library
    bool? localLibraryEnabled,
    String? localLibraryPath,
    bool? localLibraryShowDuplicates,
    // Tutorial
    bool? hasCompletedTutorial,
    // Lyrics providers
    List<String>? lyricsProviders,
    bool? lyricsIncludeTranslationNetease,
    bool? lyricsIncludeRomanizationNetease,
    bool? lyricsMultiPersonWordByWord,
    String? musixmatchLanguage,
  }) {
    return AppSettings(
      defaultService: defaultService ?? this.defaultService,
      audioQuality: audioQuality ?? this.audioQuality,
      filenameFormat: filenameFormat ?? this.filenameFormat,
      downloadDirectory: downloadDirectory ?? this.downloadDirectory,
      storageMode: storageMode ?? this.storageMode,
      downloadTreeUri: downloadTreeUri ?? this.downloadTreeUri,
      autoFallback: autoFallback ?? this.autoFallback,
      embedLyrics: embedLyrics ?? this.embedLyrics,
      maxQualityCover: maxQualityCover ?? this.maxQualityCover,
      isFirstLaunch: isFirstLaunch ?? this.isFirstLaunch,
      concurrentDownloads: concurrentDownloads ?? this.concurrentDownloads,
      checkForUpdates: checkForUpdates ?? this.checkForUpdates,
      updateChannel: updateChannel ?? this.updateChannel,
      hasSearchedBefore: hasSearchedBefore ?? this.hasSearchedBefore,
      folderOrganization: folderOrganization ?? this.folderOrganization,
      useAlbumArtistForFolders:
          useAlbumArtistForFolders ?? this.useAlbumArtistForFolders,
      usePrimaryArtistOnly: usePrimaryArtistOnly ?? this.usePrimaryArtistOnly,
      filterContributingArtistsInAlbumArtist:
          filterContributingArtistsInAlbumArtist ??
          this.filterContributingArtistsInAlbumArtist,
      historyViewMode: historyViewMode ?? this.historyViewMode,
      historyFilterMode: historyFilterMode ?? this.historyFilterMode,
      askQualityBeforeDownload:
          askQualityBeforeDownload ?? this.askQualityBeforeDownload,
      spotifyClientId: spotifyClientId ?? this.spotifyClientId,
      spotifyClientSecret: spotifyClientSecret ?? this.spotifyClientSecret,
      useCustomSpotifyCredentials:
          useCustomSpotifyCredentials ?? this.useCustomSpotifyCredentials,
      metadataSource: metadataSource ?? this.metadataSource,
      enableLogging: enableLogging ?? this.enableLogging,
      useExtensionProviders:
          useExtensionProviders ?? this.useExtensionProviders,
      searchProvider: clearSearchProvider
          ? null
          : (searchProvider ?? this.searchProvider),
      separateSingles: separateSingles ?? this.separateSingles,
      albumFolderStructure: albumFolderStructure ?? this.albumFolderStructure,
      showExtensionStore: showExtensionStore ?? this.showExtensionStore,
      locale: locale ?? this.locale,
      lyricsMode: lyricsMode ?? this.lyricsMode,
      tidalHighFormat: tidalHighFormat ?? this.tidalHighFormat,
      useAllFilesAccess: useAllFilesAccess ?? this.useAllFilesAccess,
      autoExportFailedDownloads:
          autoExportFailedDownloads ?? this.autoExportFailedDownloads,
      downloadNetworkMode: downloadNetworkMode ?? this.downloadNetworkMode,
      // Local Library
      localLibraryEnabled: localLibraryEnabled ?? this.localLibraryEnabled,
      localLibraryPath: localLibraryPath ?? this.localLibraryPath,
      localLibraryShowDuplicates:
          localLibraryShowDuplicates ?? this.localLibraryShowDuplicates,
      // Tutorial
      hasCompletedTutorial: hasCompletedTutorial ?? this.hasCompletedTutorial,
      // Lyrics providers
      lyricsProviders: lyricsProviders ?? this.lyricsProviders,
      lyricsIncludeTranslationNetease:
          lyricsIncludeTranslationNetease ?? this.lyricsIncludeTranslationNetease,
      lyricsIncludeRomanizationNetease:
          lyricsIncludeRomanizationNetease ?? this.lyricsIncludeRomanizationNetease,
      lyricsMultiPersonWordByWord:
          lyricsMultiPersonWordByWord ?? this.lyricsMultiPersonWordByWord,
      musixmatchLanguage: musixmatchLanguage ?? this.musixmatchLanguage,
    );
  }

  factory AppSettings.fromJson(Map<String, dynamic> json) =>
      _$AppSettingsFromJson(json);
  Map<String, dynamic> toJson() => _$AppSettingsToJson(this);
}
